open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = {
    clock : 'a; [@bits 1]
    enable_pipeline : 'a; [@bits 1]
    writeback_reg_write_enable : 'a; [@bits 1]
    writeback_address : 'a; [@bits 5]
    writeback_data : 'a; [@bits 32]
    instruction : 'a; [@bits 32]
    e_alu_output : 'a; [@bits 32]
    m_alu_output : 'a; [@bits 32]
    m_data_output : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    control_signals : 'a Control_unit.Control_signals.t;
    alu_a : 'a; [@bits 32]
    alu_b : 'a; [@bits 32]
    rdest : 'a; [@bits 5]
    se_imm : 'a; [@bits 32]
    alu_imm : 'a; [@bits 32]
    addr : 'a; [@bits 26]
  }
  [@@deriving sexp_of, hardcaml]
end

let regfile rs rt clock write_enable write_address write_data =
  let write_port =
    { write_clock = clock; write_address; write_enable; write_data }
  in
  let number_of_regs = 32 in
  let regs =
    multiport_memory number_of_regs ~write_ports:[| write_port |]
      ~read_addresses:[| rs; rt |]
  in
  let alu_a =
    mux2 (write_enable &: (write_address ==: rs)) write_data regs.(0)
  in
  let alu_b =
    mux2 (write_enable &: (write_address ==: rt)) write_data regs.(1)
  in

  (alu_a, alu_b)

let stall_signals scope (sigs : _ Control_unit.Control_signals.t) rs rt e_dest
    e_sel_mem_for_reg_data =
  let stall_unit =
    Stall_unit.hierarchical scope { rs; rt; e_dest; e_sel_mem_for_reg_data }
  in
  let stall_pc = stall_unit.stall_pc in
  {
    sigs with
    stall_pc;
    reg_write_enable = mux2 stall_pc gnd sigs.reg_write_enable;
    mem_write_enable = mux2 stall_pc gnd sigs.mem_write_enable;
  }

let circuit_impl (scope : Scope.t) (input : _ I.t) =
  let enable = input.enable_pipeline in

  let control_unit =
    Control_unit.hierarchical scope { instruction = input.instruction }
  in

  let parsed = control_unit.parsed_instruction in
  let rs_val, rt_val =
    regfile parsed.rs parsed.rt input.clock input.writeback_reg_write_enable
      input.writeback_address input.writeback_data
  in

  let r = Reg_spec.create ~clock:input.clock () in
  let e_dest = reg ~enable r parsed.rdest in
  let m_dest = pipeline ~n:2 ~enable r parsed.rdest in

  let m2reg = control_unit.control_signals.sel_mem_for_reg_data in
  let wreg = control_unit.control_signals.reg_write_enable in
  let e_sel_mem_for_reg_data = reg ~enable r m2reg in
  let m_sel_mem_for_reg_data = pipeline ~n:2 ~enable r m2reg in
  let e_reg_write_enable = reg ~enable r wreg in
  let m_reg_write_enable = pipeline ~n:2 ~enable r wreg in

  let full_control_signals =
    stall_signals scope control_unit.control_signals parsed.rs parsed.rt e_dest
      e_sel_mem_for_reg_data
  in

  let e_stalled = reg ~enable r full_control_signals.stall_pc in

  let forwarding_unit_inputs reg reg_value =
    {
      Forwarding_unit.I.options =
        {
          Forwarding_unit.Data_options.reg_value;
          e_alu_output = input.e_alu_output;
          m_alu_output = input.m_alu_output;
          m_data_output = input.m_data_output;
        };
      controls =
        {
          Forwarding_unit.Controls.e_sel_mem_for_reg_data;
          m_sel_mem_for_reg_data;
          e_reg_write_enable;
          m_reg_write_enable;
          e_stalled;
        };
      source = reg;
      e_dest;
      m_dest;
    }
  in

  let fwd_a =
    Forwarding_unit.hierarchical scope (forwarding_unit_inputs parsed.rs rs_val)
  in
  let fwd_b =
    Forwarding_unit.hierarchical scope (forwarding_unit_inputs parsed.rt rt_val)
  in

  let check_zero_reg reg fwd =
    mux2 (reg ==: of_string "5'b0") (of_string "32'b0") fwd
  in

  let alu_a = check_zero_reg parsed.rs fwd_a.forward_data in
  let alu_b = check_zero_reg parsed.rt fwd_b.forward_data in

  {
    O.control_signals = full_control_signals;
    alu_a;
    alu_b;
    rdest = parsed.rdest;
    se_imm = parsed.se_imm;
    alu_imm = parsed.alu_imm;
    addr = parsed.addr;
  }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"instruction_decode" circuit_impl_exn input
