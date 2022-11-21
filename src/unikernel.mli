module Make
    (Pclock : Mirage_clock.PCLOCK)
    (Time : Mirage_time.S)
    (Stack : Tcpip.Stack.V4V6)
    (Random : Mirage_random.S)
    (Mclock : Mirage_clock.MCLOCK) :
sig
  val start :
    unit ->
    unit ->
    Stack.t ->
    unit ->
    unit ->
    unit Lwt.t
end
