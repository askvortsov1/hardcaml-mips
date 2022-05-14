open Hardcaml
open Hardcaml_waveterm
open Mips.Memory
module Simulator = Cyclesim.With_interface (I) (O)

type test_input = {
  write_enable : string;
  write_data : string;
  data_address : string;
}

let testbench () =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl scope) in
  let waves, sim = Waveform.create sim in
  let inputs = Cyclesim.inputs sim in

  let step ~test =
    inputs.write_enable := Bits.of_string test.write_enable;
    inputs.read_addr := Bits.of_string test.data_address;
    inputs.write_addr := Bits.of_string test.data_address;
    inputs.write_data := Bits.of_string test.write_data;
    Cyclesim.cycle sim
  in

  step
    ~test:
      { write_enable = "1'h0"; data_address = "32'h9"; write_data = "32'h7" };
  (* alu_a should now be 8 after this step *)
  step
    ~test:
      { write_enable = "1'h0"; data_address = "32'h9"; write_data = "32'h6" };

  (* Memory should be 0 since everything has been disabled so far *)
  step
    ~test:
      { write_enable = "1'h1"; data_address = "32'h9"; write_data = "32'h86" };

  step
    ~test:
      { write_enable = "1'h0"; data_address = "32'h9"; write_data = "32'h6" };
  (* Now we can read what we wrote.
   * It's delayed by a stage since the simulator isn't half-cycle accurate
   * (see test_instruction_decode for more details) but we don't care about
   * that for data memory.
   *)
  waves

let%expect_test "can we read and write to/from data memory properly" =
  let waves = testbench () in
  Waveform.print ~wave_width:4 ~display_width:90 ~display_height:35 waves;
  [%expect
    {|
    ┌Signals───────────┐┌Waves───────────────────────────────────────────────────────────────┐
    │clock             ││┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐  │
    │                  ││     └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └──│
    │                  ││────────────────────────────────────────                            │
    │read_addr         ││ 00000009                                                           │
    │                  ││────────────────────────────────────────                            │
    │                  ││────────────────────────────────────────                            │
    │write_addr        ││ 00000009                                                           │
    │                  ││────────────────────────────────────────                            │
    │                  ││──────────┬─────────┬─────────┬─────────                            │
    │write_data        ││ 00000007 │00000006 │00000086 │00000006                             │
    │                  ││──────────┴─────────┴─────────┴─────────                            │
    │write_enable      ││                    ┌─────────┐                                     │
    │                  ││────────────────────┘         └─────────                            │
    │io_busy           ││                                                                    │
    │                  ││────────────────────────────────────────                            │
    │                  ││──────────────────────────────┬─────────                            │
    │read_data         ││ 00000000                     │00000086                             │
    │                  ││──────────────────────────────┴─────────                            │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    │                  ││                                                                    │
    └──────────────────┘└────────────────────────────────────────────────────────────────────┘ |}]
