open Hardcaml
open Hardcaml_waveterm
open Mips.Writeback
module Simulator = Cyclesim.With_interface (I) (O)

let testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl_exn scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step ~sel_mem_for_reg_data ~alu_result ~data_output =
    inputs.sel_mem_for_reg_data := Bits.of_string sel_mem_for_reg_data;
    inputs.alu_result := Bits.of_string alu_result;
    inputs.data_output := Bits.of_string data_output;
    Cyclesim.cycle sim
  in

  step ~sel_mem_for_reg_data:"1'h0" ~alu_result:"32'h9" ~data_output:"32'h6";

  (* Output = alu_result *)
  step ~sel_mem_for_reg_data:"1'h1" ~alu_result:"32'h9" ~data_output:"32'h6";

  (* Output = data_output *)
  step ~sel_mem_for_reg_data:"1'h0" ~alu_result:"32'h9" ~data_output:"32'h6";

  (* Output = alu_result *)
  waves

let%expect_test "writes back correct value depending on selector" =
  let waves = testbench () in
  Waveform.print ~wave_width:4 ~display_width:90 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││──────────────────────────────                                      │
    │alu_result        ││ 00000009                                                           │
    │                  ││──────────────────────────────                                      │
    │                  ││──────────────────────────────                                      │
    │data_output       ││ 00000006                                                           │
    │                  ││──────────────────────────────                                      │
    │sel_mem_for_reg_da││          ┌─────────┐                                               │
    │                  ││──────────┘         └─────────                                      │
    │                  ││──────────┬─────────┬─────────                                      │
    │writeback_data    ││ 00000009 │00000006 │00000009                                       │
    │                  ││──────────┴─────────┴─────────                                      │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]
