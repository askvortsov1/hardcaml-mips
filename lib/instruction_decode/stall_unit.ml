open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = {
    e_sel_mem_for_reg_data : 'a;
    rs : 'a; [@bits 5]
    rt : 'a; [@bits 5]
    e_dest: 'a; [@bits 5] 
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { stall_pc: 'a } [@@deriving sexp_of, hardcaml]
end 

let circuit_impl (_scope : Scope.t) (input : _ I.t) =
  let lw_in_execute = input.e_sel_mem_for_reg_data in
  let forward_from_execute = ((input.rs ==: input.e_dest) |: (input.rt ==: input.e_dest)) in
  let stall_pc = lw_in_execute &: forward_from_execute in

  { O.stall_pc }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"stall_unit" circuit_impl_exn input
