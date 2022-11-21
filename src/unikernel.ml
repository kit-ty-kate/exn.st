open Lwt.Infix

module Make
    (Pclock : Mirage_clock.PCLOCK)
    (Time : Mirage_time.S)
    (Stack : Tcpip.Stack.V4V6)
    (Random : Mirage_random.S)
    (Mclock : Mirage_clock.MCLOCK) =
struct
  module D = Dispatch.Make ()
  module LE_mirage = LE_mirage.Make (Time) (Stack) (Random) (Mclock) (Pclock)

  let start _pclock _time stackv4v6 _random _mclock =
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
    let handlers =
      Minimal_http.server_handler
        ~error_handler:(fun _ -> ()) (* TODO *)
        ~request_handler:D.dispatcher
    in
    LE_mirage.with_lets_encrypt_certificates
      ~port:(Key_gen.https_port ())
      ~production:(Key_gen.letsencrypt_production ())
      stackv4v6 config handlers >>= function
    | Ok () -> Lwt.return_unit
    | Error (`Msg msg) ->
        Dispatch.Https_log.info (fun f -> f "Error in paf-le.mirage: %s" msg);
        Lwt.return_unit
end
