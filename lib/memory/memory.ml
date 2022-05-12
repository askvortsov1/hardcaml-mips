open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = {
    clock : 'a;
    mem_write_enable : 'a;
    write_addr : 'a; [@bits 32]
    write_data : 'a; [@bits 32]
    read_addr : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { data_output : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
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
  let data_output =
    data_memory input.clock input.mem_write_enable input.write_data input.write_addr input.read_addr
  in
  { O.data_output }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"memory" circuit_impl_exn input
