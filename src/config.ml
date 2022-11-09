open Mirage

let stack = generic_stackv4v6 default_network
let data_key = Key.(value @@ kv_ro ~group:"data" ())
let data = generic_kv_ro ~key:data_key "htdocs"

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
    package "magic-mime";
    package "paf_le_highlevel";
  ] in
  let keys = [
    Key.abstract http_port;
    Key.abstract https_port;
    Key.abstract hostname;
    Key.abstract le_production;
  ] in
  main ~packages ~keys "Dispatch.HTTPS" (
    pclock @->
    kv_ro @->
    time @->
    stackv4v6 @->
    random @->
    mclock @->
    http @->
    job
  )

let () =
  register "https" [
    main $
    default_posix_clock $
    data $
    default_time $
    stack $
    default_random $
    default_monotonic_clock $
    https_srv
  ]
