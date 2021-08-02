open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = {
    pc : 'a; [@bits 32]
    prev_pc : 'a; [@bits 32]
    alu_a : 'a; [@bits 32]
    alu_b : 'a; [@bits 32]
    addr: 'a; [@bits 26]
    se_imm: 'a; [@bits 32]
    pc_sel: 'a Control_unit.Pc_sel.Binary.t;
  }

  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { next_pc : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end


let circuit_impl (_scope : Scope.t) (input : _ I.t) =
  let open Control_unit.Pc_sel.Enum in
  let pc_incr = input.pc +:. 4 in
  let branch_addr = input.prev_pc +:. 4 +: (sll input.se_imm 2) in
  let next_pc = Control_unit.Pc_sel.Binary.match_ (module Signal) input.pc_sel
  [
    Pc_incr, pc_incr;
    Jump_addr, input.pc.:[31, 28] @: (sll (uresize input.addr 28) 2);
    Jump_reg, input.alu_a;
    Branch_eq, mux2 (input.alu_a ==: input.alu_b) branch_addr pc_incr;
    Branch_neq, mux2 (input.alu_a <>: input.alu_b) branch_addr pc_incr;
  ] in

  { O.next_pc }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"gen_next_pc" circuit_impl_exn input


