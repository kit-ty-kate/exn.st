open Lwt.Infix

module type HTTP = Cohttp_mirage.Server.S
(** Common signature for http and https. *)

(* Logging *)
let https_src = Logs.Src.create "https" ~doc:"HTTPS server"

module Https_log = (val Logs.src_log https_src : Logs.LOG)

let http_src = Logs.Src.create "http" ~doc:"HTTP server"

module Http_log = (val Logs.src_log http_src : Logs.LOG)

module Dispatch (FS : Mirage_kv.RO) (S : HTTP) = struct
  let failf fmt = Fmt.kstr Lwt.fail_with fmt

  (* given a URI, find the appropriate file,
   * and construct a response with its contents. *)
  let rec dispatcher fs uri =
    match Uri.path uri with
    | "" | "/" -> dispatcher fs (Uri.with_path uri "index.html")
    | path ->
        let header =
          Cohttp.Header.init_with "Strict-Transport-Security" "max-age=31536000"
        in
        let mimetype = Magic_mime.lookup path in
        let headers = Cohttp.Header.add header "content-type" mimetype in
        Lwt.catch
          (fun () ->
            FS.get fs (Mirage_kv.Key.v path) >>= function
            | Error e -> failf "get: %a" FS.pp_error e
            | Ok body -> S.respond_string ~status:`OK ~body ~headers ())
          (fun _exn -> S.respond_not_found ())

  (* Redirect to the same address, but in https. *)
  let redirect port uri =
    let new_uri = Uri.with_scheme uri (Some "https") in
    let new_uri = Uri.with_port new_uri (Some port) in
    Http_log.info (fun f ->
        f "[%s] -> [%s]" (Uri.to_string uri) (Uri.to_string new_uri));
    let headers = Cohttp.Header.init_with "location" (Uri.to_string new_uri) in
    S.respond ~headers ~status:`Moved_permanently ~body:`Empty ()

  let serve dispatch =
    let callback (_, cid) request _body =
      let uri = Cohttp.Request.uri request in
      let cid = Cohttp.Connection.to_string cid in
      Https_log.info (fun f -> f "[%s] serving %s." cid (Uri.to_string uri));
      dispatch uri
    in
    let conn_closed (_, cid) =
      let cid = Cohttp.Connection.to_string cid in
      Https_log.info (fun f -> f "[%s] closing" cid)
    in
    S.make ~conn_closed ~callback ()
end

module HTTPS
    (Pclock : Mirage_clock.PCLOCK)
    (DATA : Mirage_kv.RO)
    (Time : Mirage_time.S)
    (Stack : Tcpip.Stack.V4V6)
    (Random : Mirage_random.S)
    (Mclock : Mirage_clock.MCLOCK)
    (Http : HTTP) =
struct
  module D = Dispatch (DATA) (Http)
  module Paf_le_highlevel = Paf_le_highlevel.Make (Time) (Stack) (Random) (Mclock) (Pclock)

  let tls_init stackv4v6 =
    let config = {
      LE.
      email = None;
      certificate_seed = None;
      certificate_key_type = `RSA;
      certificate_key_bits = None;
      hostname = Key_gen.hostname () |> Domain_name.of_string_exn |> Domain_name.host_exn;
      account_seed = None;
      account_key_type = `RSA;
      account_key_bits = None;
    } in
    Paf_le_highlevel.get_certificate
      ~yes_my_port_80_is_reachable_and_unused:stackv4v6
      ~production:(Key_gen.letsencrypt_production ())
      config
    >>= fun certificates ->
    let certificates = Result.get_ok certificates in
    let conf = Tls.Config.server ~certificates () in
    Lwt.return conf

  let start _pclock data _time stackv4v6 _random _mclock http =
    tls_init stackv4v6 >>= fun cfg ->
    let https_port = Key_gen.https_port () in
    let tls = `TLS (cfg, `TCP https_port) in
    let http_port = Key_gen.http_port () in
    let tcp = `TCP http_port in
    let https =
      Https_log.info (fun f -> f "listening on %d/TCP" https_port);
      http tls @@ D.serve (D.dispatcher data)
    in
    let http =
      Http_log.info (fun f -> f "listening on %d/TCP" http_port);
      http tcp @@ D.serve (D.redirect https_port)
    in
    Lwt.join [ https; http ]
end
