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

let testbench () =
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

  let add_rs_9_rt_8_rd_8 = "32'h01284020" in

  (* First, check that write_enable=0 doesn't write, and that initially reads 0 *)
  step
    ~test:
      {
        instruction = add_rs_9_rt_8_rd_8;
        write_enable = "1'h0";
        write_address = "5'h9";
        write_data = "32'h7";
      };
  (* rs_val should now be 8 after this step *)
  step
    ~test:
      {
        instruction = add_rs_9_rt_8_rd_8;
        write_enable = "1'h1";
        write_address = "5'h9";
        write_data = "32'h6";
      };
  (* Another test that write_enable=0 works as intended *)
  step
    ~test:
      {
        instruction = add_rs_9_rt_8_rd_8;
        write_enable = "1'h0";
        write_address = "5'h8";
        write_data = "32'h20";
      };
  (* Now both rs_val and rt_val should have values: 8 and 21 respectively *)
  step
    ~test:
      {
        instruction = add_rs_9_rt_8_rd_8;
        write_enable = "1'h1";
        write_address = "5'h8";
        write_data = "32'h21";
      };
  (* One more for good measure *)

  step
    ~test:
      {
        instruction = add_rs_9_rt_8_rd_8;
        write_enable = "1'h0";
        write_address = "5'h0";
        write_data = "32'h0";
      };

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
  let waves = testbench () in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:35 waves;
  [%expect {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │clock             ││┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐  │
    │                  ││     └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └──│
    │                  ││──────────────────────────────────────────────────                  │
    │instruction       ││ 01284020                                                           │
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
    │alu_control       ││ 2                                                                  │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │imm               ││ 00004020                                                           │
    │                  ││──────────────────────────────────────────────────                  │
    │mem_write_enable  ││                                                                    │
    │                  ││──────────────────────────────────────────────────                  │
    │                  ││──────────────────────────────────────────────────                  │
    │rdest             ││ 08                                                                 │
    │                  ││──────────────────────────────────────────────────                  │
    │reg_write_enable  ││──────────────────────────────────────────────────                  │
    │                  ││                                                                    │
    │                  ││────────────────────┬─────────────────────────────                  │
    │rs_val            ││ 00000000           │00000006                                       │
    │                  ││────────────────────┴─────────────────────────────                  │
    │                  ││────────────────────────────────────────┬─────────                  │
    │rt_val            ││ 00000000                               │00000021                   │
    │                  ││────────────────────────────────────────┴─────────                  │
    │sel_imm_for_alu   ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]
