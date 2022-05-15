open Hardcaml
open Hardcaml.Signal

module I = struct
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

module O = struct
  type 'a t = { io_busy : 'a; [@bits 1] read_data : 'a [@bits 32] }
  [@@deriving sexp_of, hardcaml]
end

let data_memory write_clock write_enable write_data write_addr read_addr =
  let write_port =
    { write_clock; write_address = write_addr; write_enable; write_data }
  in
  let mem =
    multiport_memory 512 ~write_ports:[| write_port |]
      ~read_addresses:[| read_addr |]
  in
  Array.get mem 0

let circuit_impl (_scope : Scope.t) (input : _ I.t) =
  let read_data =
    data_memory input.clock input.write_enable input.write_data input.write_addr
      input.read_addr
  in
  { O.read_data; io_busy = of_bool false }

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"memory" circuit_impl input
