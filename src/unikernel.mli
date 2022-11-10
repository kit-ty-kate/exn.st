module Make
    (Pclock : Mirage_clock.PCLOCK)
    (Time : Mirage_time.S)
    (Stack : Tcpip.Stack.V4V6)
    (Random : Mirage_random.S)
    (Mclock : Mirage_clock.MCLOCK)
    (Http : Dispatch.HTTP) :
sig
  val start :
    unit ->
    unit ->
    Stack.t ->
    unit ->
    unit ->
    ( [> `TCP of int | `TLS of Tls.Config.server * [> `TCP of int ] ] ->
      Http.t ->
      unit Http.IO.t) ->
    unit Http.IO.t

end
