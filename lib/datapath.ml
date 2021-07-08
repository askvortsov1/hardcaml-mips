open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = { clock : 'a } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { instruction : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

let create ~program (scope : Scope.t) (input : _ I.t) =
  let r = Reg_spec.create ~clock:input.clock () in

  (* Instruction Fetch Stage *)
  let pc = wire 32 in
  let pc_reg = reg ~enable:vdd r pc in
  let instruction_fetch = Instruction_fetch.hierarchical ~program scope { pc = pc_reg } in
  pc <== instruction_fetch.next_pc;

  {O.instruction = instruction_fetch.instruction};
