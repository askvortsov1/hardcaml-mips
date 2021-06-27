open Hardcaml
open Hardcaml_waveterm

module Simulator = Cyclesim.With_interface (Mips.Datapath.I) (Mips.Datapath.O)


let testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (Mips.Datapath.circuit_impl ~program:Mips.Program.sample scope) in
  let waves, sim = Waveform.create sim in
  let step () = Cyclesim.cycle sim in
  step ();
  step ();
  step ();
  step ();
  step ();
  step ();
  waves

(* Datapath doesn't increment PC yet, so it won't go to the next instruction for now. *)
let%expect_test "basic" =
  let waves = testbench () in
  Waveform.print ~wave_width:5 ~display_height:8 waves;
  [%expect
    {|
    ┌Signals────────┐┌Waves──────────────────────────────────────────────┐
    │clock          ││┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌──│
    │               ││      └─────┘     └─────┘     └─────┘     └─────┘  │
    │               ││────────────┬──────────────────────────────────────│
    │instruction    ││ 012A5820   │012A6020                              │
    │               ││────────────┴──────────────────────────────────────│
    │               ││                                                   │
    └───────────────┘└───────────────────────────────────────────────────┘
  |}]
