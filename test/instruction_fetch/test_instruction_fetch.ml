open Hardcaml
open Hardcaml_waveterm
open Mips.Instruction_fetch
module Simulator = Cyclesim.With_interface (I) (O)

(* Arbitrary values, these don't map to actual instructions. *)
let program = Mips.Program.create [ "00000008"; "00000001"; "99999999" ]

let testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl_exn program scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step ~pc =
    inputs.pc := Bits.of_string pc;
    Cyclesim.cycle sim
  in

  step ~pc:"32'h00000000";
  step ~pc:"32'h00000001";
  (* Not an increment of 4, so should get instruction rounded down *)
  step ~pc:"32'h00000004";
  step ~pc:"32'h00000008";
  step ~pc:"32'h0000000C";
  (* There are only 3 instructions, so it should return a no-op *)
  step ~pc:"32'h00000000";

  waves

let%expect_test "fetches appropriate instructions, increments PC by 4 correctly"
    =
  let waves = testbench () in
  Waveform.print ~wave_width:4 ~display_width:90 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││──────────┬─────────┬─────────┬─────────┬─────────┬─────────        │
    │pc                ││ 00000000 │00000001 │00000004 │00000008 │0000000C │00000000         │
    │                  ││──────────┴─────────┴─────────┴─────────┴─────────┴─────────        │
    │                  ││────────────────────┬─────────┬─────────┬─────────┬─────────        │
    │instruction       ││ 00000008           │00000001 │99999999 │00000000 │00000008         │
    │                  ││────────────────────┴─────────┴─────────┴─────────┴─────────        │
    │                  ││──────────┬─────────┬─────────┬─────────┬─────────┬─────────        │
    │next_pc           ││ 00000004 │00000005 │00000008 │0000000C │00000010 │00000004         │
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
