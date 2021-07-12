open Hardcaml
open Hardcaml_waveterm
open Mips.Instruction_decode
module Simulator = Cyclesim.With_interface (I) (O)

let testbench ()  =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl_exn scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step ~instruction =
    inputs.instruction := Bits.of_string instruction;
    Cyclesim.cycle sim
  in
    step ~instruction:"32'h01284020";
    step ~instruction:"32'h01284022";

  waves

  (* Until we implement regfile writes, these will always be 0. *)
  let%expect_test "rt and rs val are correct"
    =
  let waves = testbench () in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:35 waves;
  [%expect{|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││──────────┬─────────                                                │
    │instruction       ││ 01284020 │01284022                                                 │
    │                  ││──────────┴─────────                                                │
    │                  ││──────────┬─────────                                                │
    │alu_control       ││ 2        │3                                                        │
    │                  ││──────────┴─────────                                                │
    │                  ││──────────┬─────────                                                │
    │imm               ││ 00004020 │00004022                                                 │
    │                  ││──────────┴─────────                                                │
    │mem_write_enable  ││                                                                    │
    │                  ││────────────────────                                                │
    │                  ││────────────────────                                                │
    │rdest             ││ 08                                                                 │
    │                  ││────────────────────                                                │
    │reg_write_enable  ││────────────────────                                                │
    │                  ││                                                                    │
    │                  ││────────────────────                                                │
    │rs_val            ││ 00000000                                                           │
    │                  ││────────────────────                                                │
    │                  ││────────────────────                                                │
    │rt_val            ││ 00000000                                                           │
    │                  ││────────────────────                                                │
    │sel_imm_for_alu   ││                                                                    │
    │                  ││────────────────────                                                │
    │sel_mem_for_reg_da││                                                                    │
    │                  ││────────────────────                                                │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]