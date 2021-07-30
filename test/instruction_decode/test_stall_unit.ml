open Hardcaml
open Hardcaml_waveterm
open Mips.Stall_unit
module Simulator = Cyclesim.With_interface (I) (O)

let gen_testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl_exn scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step ~rs ~rt ~e_dest ~e_sel_mem_for_reg_data =
    inputs.e_sel_mem_for_reg_data := Bits.of_string e_sel_mem_for_reg_data;
    inputs.rs := Bits.of_string rs;
    inputs.rt := Bits.of_string rt;
    inputs.e_dest := Bits.of_string e_dest;

    Cyclesim.cycle sim
  in

  (waves, step)

let display_rules =
  [ Display_rule.port_name_is "stall_pc" ~wave_format:Wave_format.Bit ]

let%expect_test "Stalls if LW in execute and should forward" =
  let waves, step = gen_testbench () in
  let step_lw = step ~e_sel_mem_for_reg_data:"1'b1" in

  step_lw ~rs:"5'h8" ~rt:"5'h8" ~e_dest:"5'h8";
  step_lw ~rs:"5'h7" ~rt:"5'h8" ~e_dest:"5'h8";
  step_lw ~rs:"5'h8" ~rt:"5'h7" ~e_dest:"5'h8";

  Waveform.print ~display_rules ~wave_width:4 ~display_width:90
    ~display_height:5 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │stall_pc          ││──────────────────────────────                                      │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]

let%expect_test "Doesn't stall if not LW in execute" =
  let waves, step = gen_testbench () in

  step ~e_sel_mem_for_reg_data:"1'b1" ~rs:"5'h7" ~rt:"5'h7" ~e_dest:"5'h8";

  Waveform.print ~display_rules ~wave_width:4 ~display_width:90
    ~display_height:5 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │stall_pc          ││                                                                    │
    │                  ││──────────                                                          │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]

let%expect_test "Doesn't stall if LW in execute, but shouldn't forward" =
  let waves, step = gen_testbench () in

  step ~e_sel_mem_for_reg_data:"1'b0" ~rs:"5'h8" ~rt:"5'h8" ~e_dest:"5'h7";

  Waveform.print ~display_rules ~wave_width:4 ~display_width:90
    ~display_height:5 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │stall_pc          ││                                                                    │
    │                  ││──────────                                                          │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]
