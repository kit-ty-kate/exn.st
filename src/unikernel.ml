open Lwt.Infix

module Make
    (Pclock : Mirage_clock.PCLOCK)
    (Time : Mirage_time.S)
    (Stack : Tcpip.Stack.V4V6)
    (Random : Mirage_random.S)
    (Mclock : Mirage_clock.MCLOCK) =
struct
  module D = Dispatch.Make ()
  module LE_mirage = Paf_mirage.Make (Stack.TCP)

  let server_https stack handlers =
    let load_file filename =
      let ic = open_in filename in
      let ln = in_channel_length ic in
      let rs = Bytes.create ln in
      really_input ic rs 0 ln ;
      close_in ic ;
      Cstruct.of_bytes rs
    in
    let cert = load_file "./vendors/paf-le-chien/test/server.pem" in
    let key = load_file "./vendors/paf-le-chien/test/server.key" in
    match
      (X509.Certificate.decode_pem_multiple cert, X509.Private_key.decode_pem key)
    with
    | Ok certs, Ok (`RSA key) ->
        let tls = Tls.Config.server ~alpn_protocols:["h2"; "http/1.1"] ~certificates:(`Single (certs, `RSA key)) () in
        LE_mirage.init ~port:4343 (Stack.tcp stack) >>= fun service ->
        let https = LE_mirage.alpn_service ~tls handlers in
        let (`Initialized th) = LE_mirage.serve https service in
        th >>= fun () ->
        Lwt.return (Ok ())
    | _ -> invalid_arg "Invalid certificate or key"

  let start _pclock _time stackv4v6 _random _mclock =
    let _config = {
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
    let handlers =
      Minimal_http.server_handler
        ~error_handler:D.error
        ~request_handler:D.dispatcher
    in
    server_https stackv4v6 handlers >>= function
    | Ok () -> Lwt.return_unit
    | Error (`Msg msg) ->
        Dispatch.Https_log.info (fun f -> f "Error in paf-le.mirage: %s" msg);
        Lwt.return_unit
end
