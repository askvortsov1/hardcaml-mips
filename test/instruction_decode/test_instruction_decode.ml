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

(* We would expect the write changes to be visible on cycles 2 and 4.
 * In the simulation below, we only see them on 3 and 5.
 * This is because Hardcaml's simulator is cycle-accurate: that is,
 * it reads values at the start of each cycle.
 * However, that doesn't account for write-before-reads: writing during the
 * first half of a cycle, and reading during the second.
 * As a result, the evaluated value doesn't account for the new write.
 *)
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
    │                  ││──────────────────────────────────────────────────                  │
    │w_output          ││ 00000000                                                           │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││────────────────────┬───────────────────┬─────────                  │
    │writeback_address ││ 09                 │08                 │00                         │
    │                  ││────────────────────┴───────────────────┴─────────                  │
    │                  ││──────────┬─────────┬─────────┬─────────┬─────────                  │
    │writeback_data    ││ 00000007 │00000006 │00000020 │00000021 │00000000                   │
    │                  ││──────────┴─────────┴─────────┴─────────┴─────────                  │
    │writeback_reg_writ││          ┌─────────┐         ┌─────────┐                           │
    │                  ││──────────┘         └─────────┘         └─────────                  │
    │                  ││────────────────────┬─────────────────────────────                  │
    │alu_a             ││ 00000000           │00000006                                       │
    │                  ││────────────────────┴─────────────────────────────                  │
    │                  ││────────────────────────────────────────┬─────────                  │
    │alu_b             ││ 00000000                               │00000021                   │
    │                  ││────────────────────────────────────────┴─────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │alu_control       ││ 02                                                                 │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │alu_imm           ││ 00005020                                                           │
    │                  ││──────────────────────────────────────────────────                  │
    │mem_write_enable  ││                                                                    │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │rdest             ││ 0A                                                                 │
    │                  ││──────────────────────────────────────────────────                  │
    │reg_write_enable  ││──────────────────────────────────────────────────                  │
    │                  ││                                                                    │
    │sel_imm_for_alu   ││                                                                    │
    │                  ││──────────────────────────────────────────────────                  │
    │sel_mem_for_reg_da││                                                                    │
    │                  ││──────────────────────────────────────────────────                  │
    │sel_shift_for_alu ││                                                                    │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │ze_imm            ││ 00005020                                                           │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘
    78d48dfc69b486ccfba4fc7add29f561 |}]

let%expect_test "0 register always returns 0, regardless of actual contents" =
  let add_rs_9_rt_0_rd_8 = "32'h01004820" in
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
        write_address = "5'h8";
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
    │instruction       ││ 01004820                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │m_alu_output      ││ 00000000                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │m_data_output     ││ 00000000                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │w_output          ││ 00000000                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────┬─────────┬─────────                                      │
    │writeback_address ││ 00       │08       │00                                             │
    │                  ││──────────┴─────────┴─────────                                      │
    │                  ││──────────────────────────────                                      │
    │writeback_data    ││ 00000007                                                           │
    │                  ││──────────────────────────────                                      │
    │writeback_reg_writ││────────────────────┐                                               │
    │                  ││                    └─────────                                      │
    │                  ││────────────────────┬─────────                                      │
    │alu_a             ││ 00000000           │00000007                                       │
    │                  ││────────────────────┴─────────                                      │
    │                  ││──────────────────────────────                                      │
    │alu_b             ││ 00000000                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │alu_control       ││ 02                                                                 │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │alu_imm           ││ 00004820                                                           │
    │                  ││──────────────────────────────                                      │
    │mem_write_enable  ││                                                                    │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │rdest             ││ 09                                                                 │
    │                  ││──────────────────────────────                                      │
    │reg_write_enable  ││──────────────────────────────                                      │
    │                  ││                                                                    │
    │sel_imm_for_alu   ││                                                                    │
    │                  ││──────────────────────────────                                      │
    │sel_mem_for_reg_da││                                                                    │
    │                  ││──────────────────────────────                                      │
    │sel_shift_for_alu ││                                                                    │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │ze_imm            ││ 00004820                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘
    a75b59af4e59296a220c1f2f8da856ac |}]
