open Hardcaml
open Hardcaml_waveterm
open Mips.Datapath
module Simulator = Cyclesim.With_interface (I) (O)

let testbench n =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl Mips.Program.sample scope) in
  let waves, sim = Waveform.create sim in

  for _i = 0 to n do
    Cyclesim.cycle sim
  done;

  waves

(* Regfile initializes as all 0s,
 * and we only have add/subtract/lw/sw,
 * so the output of any writeback will always be 0. *)
let%expect_test "general integration test" =
  let waves = testbench 10 in
  Waveform.print ~wave_width:5 ~display_height:15 ~display_width:130 waves;
  [%expect{|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │clock             ││┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     │
    │                  ││      └─────┘     └─────┘     └─────┘     └─────┘     └─────┘     └─────┘     └─────┘     └─────┘     └─────│
    │                  ││────────────┬───────────┬───────────┬───────────┬───────────┬───────────┬───────────┬───────────┬───────────│
    │pc                ││ 00000000   │00000004   │00000008   │0000000C   │00000010   │00000014   │00000018   │0000001C   │00000020   │
    │                  ││────────────┴───────────┴───────────┴───────────┴───────────┴───────────┴───────────┴───────────┴───────────│
    │                  ││────────────────────────────────────────────────┬───────────┬───────────┬───────────────────────────────────│
    │writeback_data    ││ 00000000                                       │00000007   │00000008   │00000000                           │
    │                  ││────────────────────────────────────────────────┴───────────┴───────────┴───────────────────────────────────│
    │                  ││                                                                                                            │
    │                  ││                                                                                                            │
    │                  ││                                                                                                            │
    │                  ││                                                                                                            │
    │                  ││                                                                                                            │
    └──────────────────┘└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ |}]
