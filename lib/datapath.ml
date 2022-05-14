open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = {
    clock : 'a; [@bits 1]
    io_busy : 'a; [@bits 1]
    read_data : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    write_enable : 'a; [@bits 1]
    write_addr : 'a; [@bits 32]
    write_data : 'a; [@bits 32]
    read_enable : 'a; [@bits 1]
    read_addr : 'a; [@bits 32]
    writeback_data : 'a; [@bits 32]
    writeback_pc : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

let circuit_impl (program : Program.t) (scope : Scope.t) (input : _ I.t) =
  (* Stall the pipeline while devices on the bus are busy. *)
  let enable = ~:(input.io_busy) in
  let r = Reg_spec.create ~clock:input.clock () in

  (* Instruction Fetch Stage *)
  let pc = wire 32 in

  let instruction_fetch = Instruction_fetch.hierarchical program scope { pc } in

  (* Instruction Decode *)
  let reg_write_enable = wire 1 in
  let reg_write_enable_reg = pipeline ~n:3 ~enable r reg_write_enable in
  let writeback_address = wire 5 in
  let writeback_address_reg = pipeline ~n:3 ~enable r writeback_address in
  let writeback_data = wire 32 in

  let prev_stall_pc = wire 1 in
  let prev_instruction =
    pipeline ~n:2 ~enable r instruction_fetch.instruction
  in
  let curr_instruction = reg ~enable r instruction_fetch.instruction in
  let instruction = mux2 prev_stall_pc prev_instruction curr_instruction in

  let e_alu_output = wire 32 in
  let m_alu_output = wire 32 in
  let instruction_decode =
    Instruction_decode.hierarchical scope
      {
        Instruction_decode.I.clock = input.clock;
        enable_pipeline = enable;
        writeback_reg_write_enable = reg_write_enable_reg;
        writeback_address = writeback_address_reg;
        writeback_data;
        instruction;
        e_alu_output;
        m_alu_output;
        m_data_output = input.read_data;
      }
  in
  let ctrl_sigs = instruction_decode.control_signals in
  reg_write_enable <== ctrl_sigs.reg_write_enable;
  writeback_address <== instruction_decode.rdest;

  let gen_next_pc =
    Gen_next_pc.hierarchical scope
      {
        Gen_next_pc.I.alu_a = instruction_decode.alu_a;
        alu_b = instruction_decode.alu_b;
        addr = instruction_decode.addr;
        se_imm = instruction_decode.se_imm;
        pc;
        prev_pc = reg ~enable r pc;
        pc_sel = ctrl_sigs.pc_sel;
      }
  in

  let pc_reg =
    reg ~enable r (mux2 ctrl_sigs.stall_pc pc gen_next_pc.next_pc)
  in
  pc <== pc_reg;
  prev_stall_pc <== reg ~enable r ctrl_sigs.stall_pc;

  (* Instruction Execute *)
  let sel_shift_for_alu = reg ~enable r ctrl_sigs.sel_shift_for_alu in
  let sel_imm_for_alu = reg ~enable r ctrl_sigs.sel_imm_for_alu in
  let alu_control = reg ~enable r ctrl_sigs.alu_control in
  let alu_a = reg ~enable r instruction_decode.alu_a in
  let alu_b = reg ~enable r instruction_decode.alu_b in
  let alu_imm = reg ~enable r instruction_decode.alu_imm in
  let jal = reg ~enable r ctrl_sigs.jal in
  let instruction_execute =
    Instruction_execute.hierarchical scope
      {
        alu_a;
        alu_b;
        imm = alu_imm;
        sel_shift_for_alu;
        sel_imm_for_alu;
        alu_control;
        jal;
        prev2_pc = pipeline ~n:2 ~enable r pc;
      }
  in
  e_alu_output <== instruction_execute.alu_result;
  m_alu_output <== reg ~enable r instruction_execute.alu_result;

  (* Memory *)
  let mem_write_enable =
    pipeline ~n:2 ~enable r ctrl_sigs.mem_write_enable
  in
  let data = pipeline ~n:2 ~enable r instruction_decode.alu_b in
  let data_address = reg ~enable r instruction_execute.alu_result in

  (* Memory access is handled by the bus. *)

  (* Writeback *)
  let sel_mem_for_reg_data =
    pipeline ~n:3 ~enable r ctrl_sigs.sel_mem_for_reg_data
  in
  let alu_result = pipeline ~n:2 ~enable r instruction_execute.alu_result in
  let data_output = reg ~enable r input.read_data in

  let writeback =
    Writeback.hierarchical scope
      { Writeback.I.sel_mem_for_reg_data; alu_result; data_output }
  in
  writeback_data <== writeback.writeback_data;

  (* Outputs *)
  {
    O.write_enable = mem_write_enable;
    write_addr = data_address;
    write_data = data;
    read_enable = of_bool true;
    read_addr = data_address;
    writeback_data;
    writeback_pc = pipeline ~n:4 ~enable r pc;
  }

let circuit_impl_exn program scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl program scope) input

let hierarchical program scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"datapath" (circuit_impl_exn program) input
