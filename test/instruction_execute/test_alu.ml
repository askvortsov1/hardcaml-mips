open Hardcaml
open Hardcaml_waveterm
open Mips.Alu
module Simulator = Cyclesim.With_interface (I) (O)

let testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl_exn scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step ~arg_a ~arg_b ~alu_control =
    inputs.arg_a := Bits.of_string arg_a;
    inputs.arg_b := Bits.of_string arg_b;
    inputs.alu_control :=  Bits.of_constant (Signal.to_constant alu_control);
    Cyclesim.cycle sim
  in

  step ~arg_a:"32'h5" ~arg_b:"32'h10" ~alu_control:Mips.Control_unit.Alu_ops.add;
  step ~arg_a:"32'h15" ~arg_b:"32'h2" ~alu_control:Mips.Control_unit.Alu_ops.subtract;
  
  waves

let%expect_test "Operations behave as expected"
    =
  let waves = testbench () in
  Waveform.print ~wave_width:4 ~display_width:90 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││──────────┬─────────                                                │
    │alu_control       ││ 2        │3                                                        │
    │                  ││──────────┴─────────                                                │
    │                  ││──────────┬─────────                                                │
    │arg_a             ││ 00000005 │00000015                                                 │
    │                  ││──────────┴─────────                                                │
    │                  ││──────────┬─────────                                                │
    │arg_b             ││ 00000010 │00000002                                                 │
    │                  ││──────────┴─────────                                                │
    │                  ││──────────┬─────────                                                │
    │result            ││ 00000015 │00000013                                                 │
    │                  ││──────────┴─────────                                                │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘
  |}]
