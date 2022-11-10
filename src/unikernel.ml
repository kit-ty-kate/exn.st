open Lwt.Infix

module Make
    (Pclock : Mirage_clock.PCLOCK)
    (Time : Mirage_time.S)
    (Stack : Tcpip.Stack.V4V6)
    (Random : Mirage_random.S)
    (Mclock : Mirage_clock.MCLOCK)
    (Http : Dispatch.HTTP) =
struct
  module D = Dispatch.Make (Http)
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

  let start _pclock _time stackv4v6 _random _mclock http =
    tls_init stackv4v6 >>= fun cfg ->
    let https_port = Key_gen.https_port () in
    let tls = `TLS (cfg, `TCP https_port) in
    let http_port = Key_gen.http_port () in
    let tcp = `TCP http_port in
    let https =
      Dispatch.Https_log.info (fun f -> f "listening on %d/TCP" https_port);
      http tls @@ D.serve D.dispatcher
    in
    let http =
      Dispatch.Http_log.info (fun f -> f "listening on %d/TCP" http_port);
      http tcp @@ D.serve (D.redirect https_port)
    in
    Lwt.join [ https; http ]
end
