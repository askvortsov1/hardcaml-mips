open! Base
open Hardcaml
open Hardcaml_waveterm
open Mips.Instruction_decode
module Simulator = Cyclesim.With_interface (I) (O)

type test_input = {
  instruction : string;
  write_enable : string;
  write_address : string;
  write_data : string;
}

let testbench tests =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl_exn scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step ~test =
    inputs.instruction := Bits.of_string test.instruction;
    inputs.writeback_reg_write_enable := Bits.of_string test.write_enable;
    inputs.writeback_address := Bits.of_string test.write_address;
    inputs.writeback_data := Bits.of_string test.write_data;
    Cyclesim.cycle sim
  in

  List.iter tests ~f:(fun test -> step ~test);

  waves

let%expect_test "can we read and write to/from reg file properly" =
  let add_rs_9_rt_8_rd_10 = "32'h01285020" in
  let tests =
    [
      (* First, check that write_enable=0 doesn't write, and that initially reads 0 *)
      {
        instruction = add_rs_9_rt_8_rd_10;
        write_enable = "1'h0";
        write_address = "5'h9";
        write_data = "32'h7";
      };
      (* alu_a should now be 6 after this step *)
      {
        instruction = add_rs_9_rt_8_rd_10;
        write_enable = "1'h1";
        write_address = "5'h9";
        write_data = "32'h6";
      };
      (* Another test that write_enable=0 works as intended *)
      {
        instruction = add_rs_9_rt_8_rd_10;
        write_enable = "1'h0";
        write_address = "5'h8";
        write_data = "32'h20";
      };
      (* After this step, both alu_a and alu_b should have values: 6 and 21 respectively *)
      {
        instruction = add_rs_9_rt_8_rd_10;
        write_enable = "1'h1";
        write_address = "5'h8";
        write_data = "32'h21";
      };
      (* One more for good measure *)
      {
        instruction = add_rs_9_rt_8_rd_10;
        write_enable = "1'h0";
        write_address = "5'h0";
        write_data = "32'h0";
      };
    ]
  in
  let waves = testbench tests in
  Waveform.expect ~show_digest:true ~wave_width:4 ~display_width:90
    ~display_height:60 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │clock             ││┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐  │
    │                  ││     └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └──│
    │                  ││──────────────────────────────────────────────────                  │
    │e_alu_output      ││ 00000000                                                           │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │instruction       ││ 01285020                                                           │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │m_alu_output      ││ 00000000                                                           │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │m_data_output     ││ 00000000                                                           │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││────────────────────┬───────────────────┬─────────                  │
    │writeback_address ││ 09                 │08                 │00                         │
    │                  ││────────────────────┴───────────────────┴─────────                  │
    │                  ││──────────┬─────────┬─────────┬─────────┬─────────                  │
    │writeback_data    ││ 00000007 │00000006 │00000020 │00000021 │00000000                   │
    │                  ││──────────┴─────────┴─────────┴─────────┴─────────                  │
    │writeback_reg_writ││          ┌─────────┐         ┌─────────┐                           │
    │                  ││──────────┘         └─────────┘         └─────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │addr              ││ 1285020                                                            │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────┬───────────────────────────────────────                  │
    │alu_a             ││ 00000000 │00000006                                                 │
    │                  ││──────────┴───────────────────────────────────────                  │
    │                  ││──────────────────────────────┬───────────────────                  │
    │alu_b             ││ 00000000                     │00000021                             │
    │                  ││──────────────────────────────┴───────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │alu_control       ││ 02                                                                 │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │alu_imm           ││ 00005020                                                           │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │binary_variant    ││ 0                                                                  │
    │                  ││──────────────────────────────────────────────────                  │
    │jal               ││                                                                    │
    │                  ││──────────────────────────────────────────────────                  │
    │mem_write_enable  ││                                                                    │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │rdest             ││ 0A                                                                 │
    │                  ││──────────────────────────────────────────────────                  │
    │reg_write_enable  ││──────────────────────────────────────────────────                  │
    │                  ││                                                                    │
    │                  ││──────────────────────────────────────────────────                  │
    │se_imm            ││ 00005020                                                           │
    │                  ││──────────────────────────────────────────────────                  │
    │sel_imm_for_alu   ││                                                                    │
    │                  ││──────────────────────────────────────────────────                  │
    │sel_mem_for_reg_da││                                                                    │
    │                  ││──────────────────────────────────────────────────                  │
    │sel_shift_for_alu ││                                                                    │
    │                  ││──────────────────────────────────────────────────                  │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘
    a2db52bcd95918779d065e01a106df2e |}]

let%expect_test "0 register always returns 0, regardless of actual contents" =
  let add_rs_9_rt_0_rd_8 = "32'h01204020" in
  let tests =
    [
      (* First, write to the 0 register. rt should still be 0 after this. *)
      {
        instruction = add_rs_9_rt_0_rd_8;
        write_enable = "1'h1";
        write_address = "5'h0";
        write_data = "32'h7";
      };
      (* Next, write to register 8. rs should be 7 after this. *)
      {
        instruction = add_rs_9_rt_0_rd_8;
        write_enable = "1'h1";
        write_address = "5'h9";
        write_data = "32'h7";
      };
      {
        instruction = add_rs_9_rt_0_rd_8;
        write_enable = "1'h0";
        write_address = "5'h0";
        write_data = "32'h7";
      };
    ]
  in
  let waves = testbench tests in
  Waveform.expect ~show_digest:true ~wave_width:4 ~display_width:90
    ~display_height:60 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │clock             ││┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐  │
    │                  ││     └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └──│
    │                  ││──────────────────────────────                                      │
    │e_alu_output      ││ 00000000                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │instruction       ││ 01204020                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │m_alu_output      ││ 00000000                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │m_data_output     ││ 00000000                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────┬─────────┬─────────                                      │
    │writeback_address ││ 00       │09       │00                                             │
    │                  ││──────────┴─────────┴─────────                                      │
    │                  ││──────────────────────────────                                      │
    │writeback_data    ││ 00000007                                                           │
    │                  ││──────────────────────────────                                      │
    │writeback_reg_writ││────────────────────┐                                               │
    │                  ││                    └─────────                                      │
    │                  ││──────────────────────────────                                      │
    │addr              ││ 1204020                                                            │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────┬───────────────────                                      │
    │alu_a             ││ 00000000 │00000007                                                 │
    │                  ││──────────┴───────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │alu_b             ││ 00000000                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │alu_control       ││ 02                                                                 │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │alu_imm           ││ 00004020                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │binary_variant    ││ 0                                                                  │
    │                  ││──────────────────────────────                                      │
    │jal               ││                                                                    │
    │                  ││──────────────────────────────                                      │
    │mem_write_enable  ││                                                                    │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │rdest             ││ 08                                                                 │
    │                  ││──────────────────────────────                                      │
    │reg_write_enable  ││──────────────────────────────                                      │
    │                  ││                                                                    │
    │                  ││──────────────────────────────                                      │
    │se_imm            ││ 00004020                                                           │
    │                  ││──────────────────────────────                                      │
    │sel_imm_for_alu   ││                                                                    │
    │                  ││──────────────────────────────                                      │
    │sel_mem_for_reg_da││                                                                    │
    │                  ││──────────────────────────────                                      │
    │sel_shift_for_alu ││                                                                    │
    │                  ││──────────────────────────────                                      │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘
    0837c9485998e848e95e833ee6e96a37 |}]

let%expect_test "Stalls when appropriate" =
  let add_rs_9_rt_0_rd_8 = "32'h01204020" in
  let lw_into_9 = "32'h8D090000" in
  let lw_into_8 = "32'h8C080000" in
  let sw_from_8 = "32'hAD0D0000" in
  let sw_from_9 = "32'hAD2D0000" in

  let no_write =
    {
      instruction = "INVALID";
      write_enable = "1'b0";
      write_address = "5'h0";
      write_data = "32'h0";
    }
  in

  let tests =
    [
      (* Should stall here *)
      { no_write with instruction = lw_into_9 };
      { no_write with instruction = add_rs_9_rt_0_rd_8 };
      (* Shouldn't stall on the first two as no register overlap *)
      { no_write with instruction = lw_into_8 };
      { no_write with instruction = add_rs_9_rt_0_rd_8 };
      (* Should stall again, but this time mem write should be affected *)
      { no_write with instruction = lw_into_9 };
      { no_write with instruction = sw_from_9 };
      (* Shouldn't stall here either, same reason. *)
      { no_write with instruction = lw_into_9 };
      { no_write with instruction = sw_from_8 };
    ]
  in
  let waves = testbench tests in

  let display_rules =
  [ Display_rule.port_name_is_one_of ["stall_pc"; "mem_write_enable"; "reg_write_enable"] ~wave_format:Wave_format.Bit ] in
  Waveform.expect ~display_rules ~show_digest:true ~wave_width:4 ~display_width:130
    ~display_height:10 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │mem_write_enable  ││                                                                      ┌─────────                            │
    │                  ││──────────────────────────────────────────────────────────────────────┘                                     │
    │reg_write_enable  ││──────────┐         ┌─────────────────────────────┐         ┌─────────┐                                     │
    │                  ││          └─────────┘                             └─────────┘         └─────────                            │
    │stall_pc          ││          ┌─────────┐                             ┌─────────┐                                               │
    │                  ││──────────┘         └─────────────────────────────┘         └───────────────────                            │
    │                  ││                                                                                                            │
    │                  ││                                                                                                            │
    └──────────────────┘└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
    43bb3a6f7d51a977a80885a85a181a22 |}]
