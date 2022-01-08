open Hardcaml

module Word_with_valid : sig
  include Interface.S with type 'a t = 'a With_valid.t
end

module Tx_buffer: sig
  val create: clock:Signal.t -> clear:Signal.t -> Signal.t Word_with_valid.t -> Signal.t Hardcaml_arty.Uart.Byte_with_valid.t
end