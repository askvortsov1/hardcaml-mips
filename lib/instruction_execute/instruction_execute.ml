open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = {
    alu_a : 'a; [@bits 32]
    alu_b : 'a; [@bits 32]
    imm : 'a; [@bits 32]
    sel_shift_for_alu: 'a;
    sel_imm_for_alu: 'a;
    alu_control : 'a; [@bits (width Control_unit.Alu_ops.default)]
    jal : 'a;
    prev2_pc : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { alu_result : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

let circuit_impl (scope : Scope.t) (input : _ I.t) =
  let shift_amount = uresize input.imm.:[10, 6] 32 in
  let arg_a = mux2 input.sel_shift_for_alu shift_amount input.alu_a in
  let arg_b = mux2 input.sel_imm_for_alu input.imm input.alu_b in
  let alu = Alu.hierarchical scope { Alu.I.arg_a; arg_b; alu_control = input.alu_control} in
  let alu_result = mux2 input.jal (input.prev2_pc +:. 8) alu.result in
  { O.alu_result }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"instruction_execute" circuit_impl_exn input
