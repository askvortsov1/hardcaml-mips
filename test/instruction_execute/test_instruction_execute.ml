open Hardcaml
open Hardcaml_waveterm
open Mips.Instruction_execute
module Simulator = Cyclesim.With_interface (I) (O)

let testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl_exn scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step ~sel_shift_for_alu ~sel_imm_for_alu ~jal =
    inputs.sel_shift_for_alu := Bits.of_string sel_shift_for_alu;
    inputs.sel_imm_for_alu := Bits.of_string sel_imm_for_alu;
    inputs.alu_a := Bits.of_string "32'h1";
    inputs.alu_b := Bits.of_string "32'h2";
    inputs.imm := Bits.of_string "32'h183";
    inputs.jal := Bits.of_string jal;
    inputs.prev2_pc := Bits.of_string "32'h100";
    inputs.alu_control :=  Bits.of_constant (Signal.to_constant Mips.Control_unit.Alu_ops.add);
    Cyclesim.cycle sim
  in
  
  step, waves

let%expect_test "Uses control selector properly for ALU inputs"
    =
  let step, waves = testbench () in

  let step = step ~jal:"1'b0" in

  step ~sel_shift_for_alu:"1'b0" ~sel_imm_for_alu:"1'b0";
  step ~sel_shift_for_alu:"1'b0" ~sel_imm_for_alu:"1'b1";
  step ~sel_shift_for_alu:"1'b1" ~sel_imm_for_alu:"1'b0";
  step ~sel_shift_for_alu:"1'b1" ~sel_imm_for_alu:"1'b1";
  
  Waveform.print ~wave_width:4 ~display_height:30 ~display_width:90 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││────────────────────────────────────────                            │
    │alu_a             ││ 00000001                                                           │
    │                  ││────────────────────────────────────────                            │
    │                  ││────────────────────────────────────────                            │
    │alu_b             ││ 00000002                                                           │
    │                  ││────────────────────────────────────────                            │
    │                  ││────────────────────────────────────────                            │
    │alu_control       ││ 02                                                                 │
    │                  ││────────────────────────────────────────                            │
    │                  ││────────────────────────────────────────                            │
    │imm               ││ 00000183                                                           │
    │                  ││────────────────────────────────────────                            │
    │jal               ││                                                                    │
    │                  ││────────────────────────────────────────                            │
    │                  ││────────────────────────────────────────                            │
    │prev2_pc          ││ 00000100                                                           │
    │                  ││────────────────────────────────────────                            │
    │sel_imm_for_alu   ││          ┌─────────┐         ┌─────────                            │
    │                  ││──────────┘         └─────────┘                                     │
    │sel_shift_for_alu ││                    ┌───────────────────                            │
    │                  ││────────────────────┘                                               │
    │                  ││──────────┬─────────┬─────────┬─────────                            │
    │alu_result        ││ 00000003 │00000184 │00000008 │00000189                             │
    │                  ││──────────┴─────────┴─────────┴─────────                            │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘
  |}]

  let%expect_test "jal mux"
    =
  let step, waves = testbench () in

  let step = step ~jal:"1'b1" in

  step ~sel_shift_for_alu:"1'b0" ~sel_imm_for_alu:"1'b0";
  step ~sel_shift_for_alu:"1'b0" ~sel_imm_for_alu:"1'b1";
  step ~sel_shift_for_alu:"1'b1" ~sel_imm_for_alu:"1'b0";
  step ~sel_shift_for_alu:"1'b1" ~sel_imm_for_alu:"1'b1";

  Waveform.print ~wave_width:4 ~display_height:30 ~display_width:90 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││────────────────────────────────────────                            │
    │alu_a             ││ 00000001                                                           │
    │                  ││────────────────────────────────────────                            │
    │                  ││────────────────────────────────────────                            │
    │alu_b             ││ 00000002                                                           │
    │                  ││────────────────────────────────────────                            │
    │                  ││────────────────────────────────────────                            │
    │alu_control       ││ 02                                                                 │
    │                  ││────────────────────────────────────────                            │
    │                  ││────────────────────────────────────────                            │
    │imm               ││ 00000183                                                           │
    │                  ││────────────────────────────────────────                            │
    │jal               ││────────────────────────────────────────                            │
    │                  ││                                                                    │
    │                  ││────────────────────────────────────────                            │
    │prev2_pc          ││ 00000100                                                           │
    │                  ││────────────────────────────────────────                            │
    │sel_imm_for_alu   ││          ┌─────────┐         ┌─────────                            │
    │                  ││──────────┘         └─────────┘                                     │
    │sel_shift_for_alu ││                    ┌───────────────────                            │
    │                  ││────────────────────┘                                               │
    │                  ││────────────────────────────────────────                            │
    │alu_result        ││ 00000108                                                           │
    │                  ││────────────────────────────────────────                            │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘
  |}]
 