open Hardcaml
open Hardcaml_waveterm
open Mips.Instruction_fetch
module Simulator = Cyclesim.With_interface (I) (O)

let testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (create scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in
  let step ~pc =
    inputs.pc := Bits.of_string pc;
    Cyclesim.cycle sim
  in
  step ~pc:"32'h00000000";
  step ~pc:"32'h00000001";
  step ~pc:"32'h00000002";
  step ~pc:"32'h00000003";
  step ~pc:"32'h00000004";
  step ~pc:"32'h00000000";
  waves

let%expect_test "basic" =
  let waves = testbench () in
  Waveform.print ~wave_width:4 ~display_width:90 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││──────────┬─────────┬─────────┬─────────┬─────────┬─────────        │
    │pc                ││ 00000000 │00000001 │00000002 │00000003 │00000004 │00000000         │
    │                  ││──────────┴─────────┴─────────┴─────────┴─────────┴─────────        │
    │                  ││────────────────────────────────────────────────────────────        │
    │instruction       ││ 014B4820                                                           │
    │                  ││────────────────────────────────────────────────────────────        │
    │                  ││──────────┬─────────┬─────────┬─────────┬─────────┬─────────        │
    │next_pc           ││ 00000004 │00000005 │00000006 │00000007 │00000008 │00000004         │
    │                  ││──────────┴─────────┴─────────┴─────────┴─────────┴─────────        │
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
