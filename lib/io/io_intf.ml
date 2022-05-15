open Hardcaml
open Hardcaml.Signal

module type Io_intf = sig
  module I : sig
    type 'a t = {
      clock : 'a; [@bits 1]
      write_enable : 'a; [@bits 1]
      write_addr : 'a; [@bits 32]
      write_data : 'a; [@bits 32]
      read_enable : 'a; [@bits 1]
      read_addr : 'a; [@bits 32]
    }
    [@@deriving sexp_of, hardcaml]    
  end

  module O : sig
    type 'a t = {
      io_busy : 'a; [@bits 1]
      read_data : 'a; [@bits 32]
    }
    [@@deriving sexp_of, hardcaml]
  end

  val circuit_impl : Scope.t -> t I.t -> t O.t

  val hierarchical : Scope.t -> t I.t -> t O.t
end
