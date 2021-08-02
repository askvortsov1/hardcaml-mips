open Hardcaml
open Hardcaml_waveterm
open Mips.Datapath
module Simulator = Cyclesim.With_interface (I) (O)


let testbench n =
  let scope = Scope.create ~flatten_design:true () in
  let sim = Simulator.create (circuit_impl Mips.Program.sample scope) in
  let waves, sim = Waveform.create sim in

  for _i = 0 to n do
    Cyclesim.cycle sim
  done;

  waves

let () =
  let waves = testbench 150 in
  Hardcaml_waveterm_interactive.run ~wave_width:5 ~signals_width:30 waves