open Hardcaml
open Hardcaml_waveterm
open Mips.Delay_test_io
module Simulator = Cyclesim.With_interface (I) (O)

let testbench enableds =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step read_enabled write_enabled =
    inputs.read_enable := Bits.of_bool read_enabled;
    inputs.write_enable := Bits.of_bool write_enabled;
    Cyclesim.cycle sim
  in

  List.iter
    (fun (read_enabled, write_enabled) -> step read_enabled write_enabled)
    enableds;

  waves

let%expect_test "stays in not stalling state if nothing happens" =
  let pattern =
    [
      (false, false);
      (false, false);
      (false, false);
      (false, false);
      (false, false);
      (false, false);
    ]
  in
  let waves = testbench pattern in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:13 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │clock             ││┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐  │
    │                  ││     └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └──│
    │read_enable       ││                                                                    │
    │                  ││────────────────────────────────────────────────────────────        │
    │write_enable      ││                                                                    │
    │                  ││────────────────────────────────────────────────────────────        │
    │io_busy           ││                                                                    │
    │                  ││────────────────────────────────────────────────────────────        │
    │                  ││────────────────────────────────────────────────────────────        │
    │read_data         ││ 00000000                                                           │
    │                  ││────────────────────────────────────────────────────────────        │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]

let%expect_test "stalls for correct number of cycles if write happens" =
  let pattern =
    [
      (false, false);
      (false, true);
      (false, false);
      (false, false);
      (false, false);
      (false, false);
    ]
  in
  let waves = testbench pattern in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:13 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │clock             ││┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐  │
    │                  ││     └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └──│
    │read_enable       ││                                                                    │
    │                  ││────────────────────────────────────────────────────────────        │
    │write_enable      ││          ┌─────────┐                                               │
    │                  ││──────────┘         └───────────────────────────────────────        │
    │io_busy           ││          ┌───────────────────────────────────────┐                 │
    │                  ││──────────┘                                       └─────────        │
    │                  ││────────────────────────────────────────────────────────────        │
    │read_data         ││ 00000000                                                           │
    │                  ││────────────────────────────────────────────────────────────        │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]

let%expect_test "stalls for correct number of cycles if read and write happen \
                 concurrently" =
  let pattern =
    [
      (false, false);
      (true, true);
      (false, false);
      (false, false);
      (false, false);
      (false, false);
    ]
  in
  let waves = testbench pattern in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:13 waves;
  [%expect
    {|
        ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
        │clock             ││┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐  │
        │                  ││     └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └──│
        │read_enable       ││          ┌─────────┐                                               │
        │                  ││──────────┘         └───────────────────────────────────────        │
        │write_enable      ││          ┌─────────┐                                               │
        │                  ││──────────┘         └───────────────────────────────────────        │
        │io_busy           ││          ┌───────────────────────────────────────┐                 │
        │                  ││──────────┘                                       └─────────        │
        │                  ││──────────────────────────────┬─────────┬───────────────────        │
        │read_data         ││ 00000000                     │0000001E │00000000                   │
        │                  ││──────────────────────────────┴─────────┴───────────────────        │
        └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]

let%expect_test "stalls for correct number of cycles when reads not back to \
                 back" =
  let pattern =
    [
      (false, false);
      (true, false);
      (false, false);
      (false, false);
      (true, false);
      (false, false);
      (false, false);
      (false, false);
    ]
  in
  let waves = testbench pattern in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:13 waves;
  [%expect
    {|
        ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
        │clock             ││┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐  │
        │                  ││     └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └──│
        │read_enable       ││          ┌─────────┐                   ┌─────────┐                 │
        │                  ││──────────┘         └───────────────────┘         └─────────────────│
        │write_enable      ││                                                                    │
        │                  ││────────────────────────────────────────────────────────────────────│
        │io_busy           ││          ┌───────────────────┐         ┌───────────────────┐       │
        │                  ││──────────┘                   └─────────┘                   └───────│
        │                  ││──────────────────────────────┬─────────┬───────────────────┬───────│
        │read_data         ││ 00000000                     │0000001E │00000000           │0000001│
        │                  ││──────────────────────────────┴─────────┴───────────────────┴───────│
        └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]

let%expect_test "when ops back to back, will always halt after first one." =
  let pattern =
    [
      (false, false);
      (true, false);
      (false, false);
      (true, false);
      (false, false);
      (false, false);
      (false, false);
    ]
  in
  let waves = testbench pattern in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:13 waves;
  [%expect
    {|
                ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
                │clock             ││┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐  │
                │                  ││     └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └──│
                │read_enable       ││          ┌─────────┐         ┌─────────┐                           │
                │                  ││──────────┘         └─────────┘         └───────────────────────────│
                │write_enable      ││                                                                    │
                │                  ││────────────────────────────────────────────────────────────────────│
                │io_busy           ││          ┌───────────────────┐                                     │
                │                  ││──────────┘                   └─────────────────────────────────────│
                │                  ││──────────────────────────────┬─────────┬───────────────────────────│
                │read_data         ││ 00000000                     │0000001E │00000000                   │
                │                  ││──────────────────────────────┴─────────┴───────────────────────────│
                └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]

let%expect_test "stalls for correct number of cycles starts with a read, ends \
                 with a write" =
  let pattern =
    [
      (true, false);
      (false, false);
      (false, false);
      (false, true);
      (false, false);
      (false, false);
      (false, false);
    ]
  in
  let waves = testbench pattern in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:13 waves;
  [%expect
    {|
                        ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
                        │clock             ││┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐  │
                        │                  ││     └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └──│
                        │read_enable       ││──────────┐                                                         │
                        │                  ││          └─────────────────────────────────────────────────────────│
                        │write_enable      ││                              ┌─────────┐                           │
                        │                  ││──────────────────────────────┘         └───────────────────────────│
                        │io_busy           ││────────────────────┐         ┌─────────────────────────────────────│
                        │                  ││                    └─────────┘                                     │
                        │                  ││────────────────────┬─────────┬─────────────────────────────────────│
                        │read_data         ││ 00000000           │0000001E │00000000                             │
                        │                  ││────────────────────┴─────────┴─────────────────────────────────────│
                        └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]
