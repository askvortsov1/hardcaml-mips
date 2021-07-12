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

(* Regfile initializes as all 0s and doesn't get written yet,
 * and we only have add/subtract/lw/sw,
 * so the output of any ALU op will always be 0. *)
let%expect_test "general integration test" =
  let waves = testbench () in
  Waveform.print ~wave_width:5 ~display_height:8 waves;
  [%expect
    {|
    ┌Signals────────┐┌Waves──────────────────────────────────────────────┐
    │clock          ││┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌──│
    │               ││      └─────┘     └─────┘     └─────┘     └─────┘  │
    │               ││───────────────────────────────────────────────────│
    │alu_result     ││ 00000000                                          │
    │               ││───────────────────────────────────────────────────│
    │               ││                                                   │
    └───────────────┘└───────────────────────────────────────────────────┘
  |}]
