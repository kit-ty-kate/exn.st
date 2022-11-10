module type HTTP = Cohttp_mirage.Server.S

module Https_log : Logs.LOG
module Http_log : Logs.LOG

module Make (S : HTTP) : sig
  val dispatcher :
    Uri.t ->
    (Cohttp.Response.t * Cohttp_lwt.Body.t) S.IO.t

  val redirect :
    int ->
    Uri.t ->
    (Cohttp.Response.t * Cohttp_lwt.Body.t) S.IO.t

  val serve :
    (Uri.t -> (Cohttp.Response.t * Cohttp_lwt.Body.t) S.IO.t) ->
    S.t
end
