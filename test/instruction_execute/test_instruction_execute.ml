open Hardcaml
open Hardcaml_waveterm
open Mips.Instruction_execute
module Simulator = Cyclesim.With_interface (I) (O)

let testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl_exn scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step ~sel_shift_for_alu ~sel_imm_for_alu =
    inputs.sel_shift_for_alu := Bits.of_string sel_shift_for_alu;
    inputs.sel_imm_for_alu := Bits.of_string sel_imm_for_alu;
    inputs.rs_val := Bits.of_string "32'h1";
    inputs.rt_val := Bits.of_string "32'h2";
    inputs.imm := Bits.of_string "32'h183";
    inputs.alu_control :=  Bits.of_constant (Signal.to_constant Mips.Control_unit.Alu_ops.add);
    Cyclesim.cycle sim
  in

  step ~sel_shift_for_alu:"1'b0" ~sel_imm_for_alu:"1'b0";
  step ~sel_shift_for_alu:"1'b0" ~sel_imm_for_alu:"1'b1";
  step ~sel_shift_for_alu:"1'b1" ~sel_imm_for_alu:"1'b0";
  step ~sel_shift_for_alu:"1'b1" ~sel_imm_for_alu:"1'b1";
  
  waves

let%expect_test "Uses control selector properly for ALU inputs"
    =
  let waves = testbench () in
  Waveform.print ~wave_width:4 ~display_height:30 ~display_width:90 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││────────────────────────────────────────                            │
    │alu_control       ││ 02                                                                 │
    │                  ││────────────────────────────────────────                            │
    │                  ││────────────────────────────────────────                            │
    │imm               ││ 00000183                                                           │
    │                  ││────────────────────────────────────────                            │
    │                  ││────────────────────────────────────────                            │
    │rs_val            ││ 00000001                                                           │
    │                  ││────────────────────────────────────────                            │
    │                  ││────────────────────────────────────────                            │
    │rt_val            ││ 00000002                                                           │
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
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘
  |}]
