open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = { clock : 'a } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { alu_result : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

let circuit_impl (program : Program.t) (scope : Scope.t) (input : _ I.t) =
  let r = Reg_spec.create ~clock:input.clock () in

  (* Instruction Fetch Stage *)
  let pc = wire 32 in
  let pc_reg = reg ~enable:vdd r pc in
  let instruction_fetch =
    Instruction_fetch.hierarchical program scope { pc = pc_reg }
  in
  pc <== instruction_fetch.next_pc;

  (* Instruction Decode *)
  let instruction_reg = reg ~enable:vdd r instruction_fetch.instruction in
  let instruction_decode = 
    Instruction_decode.hierarchical scope {instruction = instruction_reg}
  in
  let ctrl_sigs = instruction_decode.control_signals in

  (* Instruction Execute *)
  let sel_imm_for_alu = reg ~enable:vdd r ctrl_sigs.sel_imm_for_alu in
  let alu_control = reg ~enable:vdd r ctrl_sigs.alu_control in
  let rs_val = reg ~enable:vdd r instruction_decode.rs_val in
  let rt_val = reg ~enable:vdd r instruction_decode.rt_val in
  let imm = reg ~enable:vdd r instruction_decode.imm in
  let instruction_execute = Instruction_execute.hierarchical scope {
    sel_imm_for_alu;
    alu_control;
    rs_val;
    rt_val;
    imm
  } in

  (* Outputs *)
  { O.alu_result = instruction_execute.alu_result }

let circuit_impl_exn program scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl program scope) input
