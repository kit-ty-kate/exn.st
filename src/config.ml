open Mirage

let stack = generic_stackv4v6 default_network

(* set ~tls to false to get a plain-http server *)
let https_srv = cohttp_server @@ conduit_direct ~tls:true stack

let http_port =
  let doc = Key.Arg.info ~doc:"Listening HTTP port." [ "http" ] in
  Key.(create "http_port" Arg.(opt int 8080 doc))

let https_port =
  let doc = Key.Arg.info ~doc:"Listening HTTPS port." [ "https" ] in
  Key.(create "https_port" Arg.(opt int 4433 doc))

let hostname =
  let doc = Key.Arg.info ~doc:"Server hostname." [ "hostname" ] in
  Key.(create "hostname" Arg.(required string doc))

let le_production =
  let doc = Key.Arg.info ~doc:"Query Let's Encrypt production servers." [ "letsencrypt-production" ] in
  Key.(create "letsencrypt_production" Arg.(opt bool false doc))

let main =
  let packages = [
    package "uri";
    package "tyxml";
    package "magic-mime";
    package "paf_le_highlevel";
  ] in
  let keys = [
    Key.v http_port;
    Key.v https_port;
    Key.v hostname;
    Key.v le_production;
  ] in
  Mirage.main ~packages ~keys "Unikernel.Make" (
    Mirage.pclock @->
    Mirage.time @->
    Mirage.stackv4v6 @->
    Mirage.random @->
    Mirage.mclock @->
    Mirage.http @->
    Mirage.job
  )

let () =
  Mirage.register "unikernel" [
    main $
    Mirage.default_posix_clock $
    Mirage.default_time $
    stack $
    Mirage.default_random $
    Mirage.default_monotonic_clock $
    https_srv
  ]
