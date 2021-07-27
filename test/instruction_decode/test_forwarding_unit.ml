open Hardcaml
open Hardcaml_waveterm
open Mips.Forwarding_unit
module Simulator = Cyclesim.With_interface (I) (O)

let gen_testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl_exn scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step ?(e_dest = "5'h9") ?(m_dest = "5'h9") ?(e_mem2reg = "1'b0")
      ?(m_mem2reg = "1'b0") ?(e_rwrite = "1'b1") ?(m_rwrite = "1'b1") () =
    inputs.options.reg_value := Bits.of_string "32'd0";
    inputs.options.e_alu_output := Bits.of_string "32'd1";
    inputs.options.m_alu_output := Bits.of_string "32'd2";
    inputs.options.m_data_output := Bits.of_string "32'd3";
    inputs.source := Bits.of_string "5'd8";
    inputs.e_dest := Bits.of_string e_dest;
    inputs.m_dest := Bits.of_string m_dest;
    inputs.controls.e_sel_mem_for_reg_data := Bits.of_string e_mem2reg;
    inputs.controls.m_sel_mem_for_reg_data := Bits.of_string m_mem2reg;
    inputs.controls.e_reg_write_enable := Bits.of_string e_rwrite;
    inputs.controls.m_reg_write_enable := Bits.of_string m_rwrite;
    Cyclesim.cycle sim
  in
  (waves, step)

let display_rules =
  [ Display_rule.port_name_is "forward_data" ~wave_format:Wave_format.Hex ]

let%expect_test "Forwards correctly, if should forward" =
  let waves, step = gen_testbench () in

  step ~e_dest:"5'h8" ();
  step ~m_dest:"5'h8" ~m_mem2reg:"1'b0" ();
  step ~m_dest:"5'h8" ~m_mem2reg:"1'b1" ();

  Waveform.print ~display_rules ~wave_width:4 ~display_width:90
    ~display_height:5 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││──────────┬─────────┬─────────                                      │
    │forward_data      ││ 00000001 │00000002 │00000003                                       │
    │                  ││──────────┴─────────┴─────────                                      │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]

let%expect_test "Doesn't forward for instructions that don't write to registers"
    =
  let waves, step = gen_testbench () in

  step ~e_dest:"5'h8" ~e_rwrite:"1'b0" ();
  step ~m_dest:"5'h8" ~m_mem2reg:"1'b0" ~m_rwrite:"1'b0" ();
  step ~m_dest:"5'h8" ~m_mem2reg:"1'b1" ~m_rwrite:"1'b0" ();

  Waveform.print ~display_rules ~wave_width:4 ~display_width:90
    ~display_height:5 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││──────────────────────────────                                      │
    │forward_data      ││ 00000000                                                           │
    │                  ││──────────────────────────────                                      │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]

let%expect_test "Prioritizes which stage forwarding happens if dest is same" =
  let waves, step = gen_testbench () in

  step ~e_dest:"5'h8" ~m_dest:"5'h8" ~m_mem2reg:"1'b0" ();
  step ~e_dest:"5'h8" ~m_dest:"5'h8" ~m_mem2reg:"1'b1" ();

  Waveform.print ~display_rules ~wave_width:4 ~display_width:90
    ~display_height:5 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││────────────────────                                                │
    │forward_data      ││ 00000001                                                           │
    │                  ││────────────────────                                                │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]

let%expect_test "Ensures no forwarding occurs when LW is in execute stage" =
  let waves, step = gen_testbench () in

  step ~e_dest:"5'h8" ~e_mem2reg:"1'b1" ();

  Waveform.print ~display_rules ~wave_width:4 ~display_width:90
    ~display_height:5 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │                  ││──────────                                                          │
    │forward_data      ││ 00000000                                                           │
    │                  ││──────────                                                          │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]
