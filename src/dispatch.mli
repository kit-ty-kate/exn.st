module Https_log : Logs.LOG

module Make () : sig
  val dispatcher : Minimal_http.t -> unit

  val error : Minimal_http.error -> unit
end
