open Hardcaml
open Hardcaml_waveterm
open Mips_arty

module Simulator =
  Cyclesim.With_interface
    (Hardcaml_arty.User_application.I)
    (Hardcaml_arty.User_application.O)

let testbench program n =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (Wrapper.circuit_impl program scope) in
  let waves, sim = Waveform.create sim in

  for _i = 0 to n do
    Cyclesim.cycle sim
  done;

  waves

let display_rules =
  let re = Re.Posix.compile (Re.Posix.re "(clk|uart)") in
  [ Display_rule.port_name_matches re ~wave_format:Wave_format.Bit ]

let%expect_test "general integration test" =
  let waves = testbench Mips_arty.Program.sample 40 in
  Waveform.print ~display_rules ~wave_width:4 ~display_height:15
    ~display_width:140 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │clk_166           ││                                                                                                                      │
    │                  ││──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────│
    │uart_tx_valid     ││                                                                      ┌───────────────────────────────────────────────│
    │                  ││──────────────────────────────────────────────────────────────────────┘                                               │
    │                  ││──────────────────────────────────────────────────────────────────────┬───────────────────────────────────────────────│
    │uart_tx_value     ││ 00000000                                                             │01100001                                       │
    │                  ││──────────────────────────────────────────────────────────────────────┴───────────────────────────────────────────────│
    │                  ││                                                                                                                      │
    │                  ││                                                                                                                      │
    │                  ││                                                                                                                      │
    │                  ││                                                                                                                      │
    │                  ││                                                                                                                      │
    │                  ││                                                                                                                      │
    └──────────────────┘└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ |}]
