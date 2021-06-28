open Hardcaml
open Hardcaml_waveterm
open Mips.Datapath
module Simulator = Cyclesim.With_interface (I) (O)

let testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl Mips.Program.sample scope) in
  let waves, sim = Waveform.create sim in

  for _i = 0 to 5 do
    Cyclesim.cycle sim
  done;

  waves

(* Datapath doesn't increment PC yet, so it won't go to the next instruction for now. *)
let%expect_test "general integration test" =
  let waves = testbench () in
  Waveform.print ~wave_width:5 ~display_height:8 waves;
  [%expect
    {|
    ┌Signals────────┐┌Waves──────────────────────────────────────────────┐
    │clock          ││┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌──│
    │               ││      └─────┘     └─────┘     └─────┘     └─────┘  │
    │               ││────────────┬───────────┬──────────────────────────│
    │instruction    ││ 012A5820   │012A6020   │00000000                  │
    │               ││────────────┴───────────┴──────────────────────────│
    │               ││                                                   │
    └───────────────┘└───────────────────────────────────────────────────┘
  |}]
