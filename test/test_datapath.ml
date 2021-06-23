open Hardcaml
open Hardcaml_waveterm
open Mips.Datapath
module Simulator = Cyclesim.With_interface (I) (O)

let testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (create scope) in
  let waves, sim = Waveform.create sim in
  let step = Cyclesim.cycle sim in
  step;
  step;
  step;
  step;
  step;
  step;
  waves

let%expect_test "basic" =
  let waves = testbench () in
  Waveform.print ~wave_width:10 ~display_height:8 waves;
  [%expect
    {|
    ┌Signals────────┐┌Waves──────────────────────────────────────────────┐
    │               ││──────────────────────                             │
    │instruction    ││ 014B4820                                          │
    │               ││──────────────────────                             │
    │               ││                                                   │
    │               ││                                                   │
    │               ││                                                   │
    └───────────────┘└───────────────────────────────────────────────────┘
  |}]
