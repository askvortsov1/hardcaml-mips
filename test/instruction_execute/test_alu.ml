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
  step ~arg_a:"32'h10" ~arg_b:"32'h5" ~alu_control:Mips.Control_unit.Alu_ops.addu;
  step ~arg_a:"32'h000F0FF0" ~arg_b:"32'hFF0F00FF" ~alu_control:Mips.Control_unit.Alu_ops.and_;
  step ~arg_a:"32'hABCDEF01" ~arg_b:"32'h9876ABCD" ~alu_control:Mips.Control_unit.Alu_ops.lui;
  step ~arg_a:"32'h000F0FF0" ~arg_b:"32'hFF0F00FF" ~alu_control:Mips.Control_unit.Alu_ops.or_;
  step ~arg_a:"32'h0" ~arg_b:"32'hFFFFFFFF" ~alu_control:Mips.Control_unit.Alu_ops.slt;
  step ~arg_a:"32'h0" ~arg_b:"32'hFFFFFFFF" ~alu_control:Mips.Control_unit.Alu_ops.sltu;
  step ~arg_a:"32'h2" ~arg_b:"32'h8000000F0" ~alu_control:Mips.Control_unit.Alu_ops.sll;
  step ~arg_a:"32'h2" ~arg_b:"32'h8000000F0" ~alu_control:Mips.Control_unit.Alu_ops.sra;
  step ~arg_a:"32'h2" ~arg_b:"32'h8000000F0" ~alu_control:Mips.Control_unit.Alu_ops.srl;
  step ~arg_a:"32'h15" ~arg_b:"32'h2" ~alu_control:Mips.Control_unit.Alu_ops.sub;
  step ~arg_a:"32'h15" ~arg_b:"32'h2" ~alu_control:Mips.Control_unit.Alu_ops.subu;
  step ~arg_a:"32'h005F" ~arg_b:"32'hF0AF" ~alu_control:Mips.Control_unit.Alu_ops.xor;
  
  waves

let%expect_test "Operations behave as expected"
    =
  let waves = testbench () in
  Waveform.print ~wave_width:4 ~display_width:155 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                  ││──────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────   │
    │alu_control       ││ 02       │03       │04       │05       │06       │07       │08       │09       │0A       │0B       │0C       │0D       │0E          │
    │                  ││──────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────   │
    │                  ││──────────┬─────────┬─────────┬─────────┬─────────┬───────────────────┬─────────────────────────────┬───────────────────┬─────────   │
    │arg_a             ││ 00000005 │00000010 │000F0FF0 │ABCDEF01 │000F0FF0 │00000000           │00000002                     │00000015           │0000005F    │
    │                  ││──────────┴─────────┴─────────┴─────────┴─────────┴───────────────────┴─────────────────────────────┴───────────────────┴─────────   │
    │                  ││──────────┬─────────┬─────────┬─────────┬─────────┬───────────────────┬─────────────────────────────┬───────────────────┬─────────   │
    │arg_b             ││ 00000010 │00000005 │FF0F00FF │9876ABCD │FF0F00FF │FFFFFFFF           │000000F0                     │00000002           │0000F0AF    │
    │                  ││──────────┴─────────┴─────────┴─────────┴─────────┴───────────────────┴─────────────────────────────┴───────────────────┴─────────   │
    │                  ││────────────────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬───────────────────┬───────────────────┬─────────   │
    │result            ││ 00000015           │000F00F0 │ABCD0000 │FF0F0FFF │00000001 │00000000 │000003C0 │0000003C           │00000013           │0000F0F0    │
    │                  ││────────────────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴───────────────────┴───────────────────┴─────────   │
    │                  ││                                                                                                                                     │
    │                  ││                                                                                                                                     │
    │                  ││                                                                                                                                     │
    │                  ││                                                                                                                                     │
    │                  ││                                                                                                                                     │
    │                  ││                                                                                                                                     │
    └──────────────────┘└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
  |}]
