module Key = Mirage.Key
module Arg = Key.Arg

let ( @-> ) = Mirage.( @-> )
let ( $ ) = Mirage.( $ )

let stack = Mirage.generic_stackv4v6 Mirage.default_network
let dns = Mirage.generic_dns_client stack

(* set ~tls to false to get a plain-http server *)
(* let https_srv = Mirage.cohttp_server @@ Mirage.conduit_direct ~tls:true stack *)

(* TODO *)
(*
let http_port =
  let doc = Arg.info ~doc:"Listening HTTP port." [ "http" ] in
  Key.create "http_port" (Arg.opt Arg.int 8080 doc)
*)
let https_port =
  let doc = Arg.info ~doc:"Listening HTTPS port." [ "https" ] in
  Key.create "https_port" (Arg.opt Arg.int 4433 doc)

let hostname =
  let doc = Arg.info ~doc:"Server hostname." [ "hostname" ] in
  Key.create "hostname" (Arg.required Arg.string doc)

let le_production =
  let doc = Arg.info ~doc:"Query Let's Encrypt production servers." [ "letsencrypt-production" ] in
  Key.create "letsencrypt_production" (Arg.opt Arg.bool false doc)

let alpn_client =
  let dns =
    Mirage.mimic_happy_eyeballs stack dns (Mirage.generic_happy_eyeballs stack dns)
  in
  Mirage.paf_client (Mirage.tcpv4v6_of_stackv4v6 stack) dns

let main =
  let packages = [
    Mirage.package "uri";
    Mirage.package "tyxml";
    Mirage.package "magic-mime";
    Mirage.package ~sublibs:["http-server"] "letsencrypt-mirage";
    Mirage.package "minimal_http";
  ] in
  let keys = [
    (*    Key.v http_port; *)
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
    Mirage.alpn_client @->
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
    alpn_client
  ]
