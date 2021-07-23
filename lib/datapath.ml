open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = { clock : 'a } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    writeback_data : 'a; [@bits 32]
    pc : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
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
  let reg_write_enable = wire 1 in
  let reg_write_enable_reg = pipeline ~n:3 ~enable:vdd r reg_write_enable in
  let writeback_address = wire 5 in
  let writeback_address_reg = pipeline ~n:3 ~enable:vdd r writeback_address in
  let writeback_data = wire 32 in
  let instruction = reg ~enable:vdd r instruction_fetch.instruction in
  let instruction_decode =
    Instruction_decode.hierarchical scope
      {
        Instruction_decode.I.clock = input.clock;
        writeback_reg_write_enable = reg_write_enable_reg;
        writeback_address = writeback_address_reg;
        writeback_data;
        instruction;
      }
  in
  let ctrl_sigs = instruction_decode.control_signals in
  reg_write_enable <== ctrl_sigs.reg_write_enable;
  writeback_address <== instruction_decode.rdest;

  (* Instruction Execute *)
  let sel_shift_for_alu = reg ~enable:vdd r ctrl_sigs.sel_shift_for_alu in
  let sel_imm_for_alu = reg ~enable:vdd r ctrl_sigs.sel_imm_for_alu in
  let alu_control = reg ~enable:vdd r ctrl_sigs.alu_control in
  let rs_val = reg ~enable:vdd r instruction_decode.rs_val in
  let rt_val = reg ~enable:vdd r instruction_decode.rt_val in
  let alu_imm = reg ~enable:vdd r instruction_decode.alu_imm in
  let instruction_execute =
    Instruction_execute.hierarchical scope
      {
        sel_shift_for_alu;
        sel_imm_for_alu;
        alu_control;
        rs_val;
        rt_val;
        imm = alu_imm;
      }
  in

  (* Memory *)
  let mem_write_enable =
    pipeline ~n:2 ~enable:vdd r ctrl_sigs.mem_write_enable
  in
  let data = pipeline ~n:2 ~enable:vdd r instruction_decode.rs_val in
  let memory =
    Memory.hierarchical scope
      {
        Memory.I.clock = input.clock;
        mem_write_enable;
        data;
        data_address = instruction_execute.alu_result;
      }
  in

  (* Writeback *)
  let sel_mem_for_reg_data =
    pipeline ~n:3 ~enable:vdd r ctrl_sigs.sel_mem_for_reg_data
  in
  let alu_result = pipeline ~n:2 ~enable:vdd r instruction_execute.alu_result in
  let data_output = reg ~enable:vdd r memory.data_output in

  let writeback =
    Writeback.hierarchical scope
      { Writeback.I.sel_mem_for_reg_data; alu_result; data_output }
  in
  writeback_data <== writeback.writeback_data;

  (* Outputs *)
  { O.writeback_data = writeback.writeback_data; pc = pc_reg; }

let circuit_impl_exn program scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl program scope) input
