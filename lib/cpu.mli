open Hardcaml

module I = Hardcaml_arty.User_application.I

module O : sig
  type 'a t = {
    uart_tx : 'a Hardcaml_arty.Uart.Byte_with_valid.t;
    ethernet : 'a Hardcaml_arty.User_application.Ethernet.O.t;
    writeback_data : 'a;
    writeback_pc : 'a;
  }
  [@@deriving sexp_of, hardcaml]
end

val circuit_impl : Program.t -> Scope.t -> Signal.t I.t -> Signal.t O.t
