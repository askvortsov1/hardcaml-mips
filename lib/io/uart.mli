open Hardcaml
open Hardcaml.Signal

module Word_with_valid : sig
  include Hardcaml.Interface.S with type 'a t = 'a With_valid.t
end

val cycles_per_packet : int

module Rx_buffer : sig
  val create :
    clock:Signal.t ->
    read_enable:Signal.t ->
    Signal.t Hardcaml_arty.Uart.Byte_with_valid.t ->
    (Signal.t Word_with_valid.t * Signal.t)
end

module Tx_buffer : sig
  val create :
    clock:Signal.t ->
    Signal.t Word_with_valid.t ->
    (Signal.t Hardcaml_arty.Uart.Byte_with_valid.t * Signal.t)
end

module I : sig
  type 'a t = {
    clock : 'a; [@bits 1]
    write_enable : 'a; [@bits 1]
    write_addr : 'a; [@bits 32]
    write_data : 'a; [@bits 32]
    read_enable : 'a; [@bits 1]
    read_addr : 'a; [@bits 32]
    uart_rx : 'a Hardcaml_arty.Uart.Byte_with_valid.t;[@rtlprefix "rx_"]
  }
  [@@deriving sexp_of, hardcaml]
end

module O : sig
  type 'a t = {
    io_busy : 'a; [@bits 1]
    read_data : 'a; [@bits 32]
    uart_tx : 'a Hardcaml_arty.Uart.Byte_with_valid.t;[@rtlprefix "tx_"]
  }
  [@@deriving sexp_of, hardcaml]
end

val circuit_impl : Scope.t -> t I.t -> t O.t

val hierarchical : Scope.t -> t I.t -> t O.t