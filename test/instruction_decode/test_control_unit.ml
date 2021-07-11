open Hardcaml
open Hardcaml_waveterm
open Mips.Control_unit
module Simulator = Cyclesim.With_interface (I) (O)

let testbench instructions  =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl_exn scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step ~instruction =
    inputs.instruction := Bits.of_string instruction;
    Cyclesim.cycle sim
  in

  List.iter (fun instr -> step ~instruction:instr) instructions;
  waves

let%expect_test "Uses different rdest for RType and IType"
    =
  let add_rd_is_9 = "32'h014B4820"in
  let lw_rt_is_8 = "32'h8D280000" in

  let waves = testbench [add_rd_is_9; lw_rt_is_8] in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:35 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││──────────┬─────────                                                │
    │instruction       ││ 014B4820 │8D280000                                                 │
    │                  ││──────────┴─────────                                                │
    │                  ││────────────────────                                                │
    │alu_control       ││ 2                                                                  │
    │                  ││────────────────────                                                │
    │                  ││──────────┬─────────                                                │
    │imm               ││ 00004820 │00000000                                                 │
    │                  ││──────────┴─────────                                                │
    │mem_write_enable  ││                                                                    │
    │                  ││────────────────────                                                │
    │                  ││──────────┬─────────                                                │
    │rdest             ││ 09       │08                                                       │
    │                  ││──────────┴─────────                                                │
    │reg_write_enable  ││────────────────────                                                │
    │                  ││                                                                    │
    │                  ││──────────┬─────────                                                │
    │rs                ││ 0A       │09                                                       │
    │                  ││──────────┴─────────                                                │
    │                  ││──────────┬─────────                                                │
    │rt                ││ 0B       │08                                                       │
    │                  ││──────────┴─────────                                                │
    │sel_imm_for_alu   ││          ┌─────────                                                │
    │                  ││──────────┘                                                         │
    │sel_mem_for_reg_da││          ┌─────────                                                │
    │                  ││──────────┘                                                         │
    │                  ││────────────────────                                                │
    │shamt             ││ 00                                                                 │
    │                  ││────────────────────                                                │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘
  |}]


let%expect_test "Control signals are what they should be for R-Type"
    =
  let add_instr = "32'h01284020" in
  let sub_instr = "32'h01284022" in
  let waves = testbench [add_instr; sub_instr] in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:35 waves;
  [%expect
    {|
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
    │rs                ││ 09                                                                 │
    │                  ││────────────────────                                                │
    │                  ││────────────────────                                                │
    │rt                ││ 08                                                                 │
    │                  ││────────────────────                                                │
    │sel_imm_for_alu   ││                                                                    │
    │                  ││────────────────────                                                │
    │sel_mem_for_reg_da││                                                                    │
    │                  ││────────────────────                                                │
    │                  ││────────────────────                                                │
    │shamt             ││ 00                                                                 │
    │                  ││────────────────────                                                │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘
  |}]


let%expect_test "Control signals are what they should be for I-Type"
    =
  let lw_instr = "32'h8D280000" in
  let sw_instr = "32'hAD280000" in
  let waves = testbench [lw_instr; sw_instr] in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:35 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││──────────┬─────────                                                │
    │instruction       ││ 8D280000 │AD280000                                                 │
    │                  ││──────────┴─────────                                                │
    │                  ││────────────────────                                                │
    │alu_control       ││ 2                                                                  │
    │                  ││────────────────────                                                │
    │                  ││────────────────────                                                │
    │imm               ││ 00000000                                                           │
    │                  ││────────────────────                                                │
    │mem_write_enable  ││          ┌─────────                                                │
    │                  ││──────────┘                                                         │
    │                  ││────────────────────                                                │
    │rdest             ││ 08                                                                 │
    │                  ││────────────────────                                                │
    │reg_write_enable  ││──────────┐                                                         │
    │                  ││          └─────────                                                │
    │                  ││────────────────────                                                │
    │rs                ││ 09                                                                 │
    │                  ││────────────────────                                                │
    │                  ││────────────────────                                                │
    │rt                ││ 08                                                                 │
    │                  ││────────────────────                                                │
    │sel_imm_for_alu   ││────────────────────                                                │
    │                  ││                                                                    │
    │sel_mem_for_reg_da││──────────┐                                                         │
    │                  ││          └─────────                                                │
    │                  ││────────────────────                                                │
    │shamt             ││ 00                                                                 │
    │                  ││────────────────────                                                │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘
  |}]
