open Hardcaml
open Hardcaml_waveterm
open Mips.Cpu

module Simulator = Cyclesim.With_interface (I) (O)

let testbench n =
  let scope = Scope.create ~auto_label_hierarchical_ports:true ~flatten_design:true () in
  let program =
    Mips.Program.create
      [
        "3C08FFFF" (* lui t0 0xFFFF *);
        "3508FFFF" (* ori t0 t0 0xFFFF *);
        "214A0008" (* addi $t2 $t2 0x0008 *);
        "216B0004" (* addi $t3 $t3 0x0004 *);
        "8D0C0000" (* lw $t4 0($t0) *);
        "000C6820" (* add $t5 $zero $t4 *);
        "000C6820" (* add $t5 $zero $t4 *);
        "000C6820" (* add $t5 $zero $t4 *);
        "000C6820" (* add $t5 $zero $t4 *);
        "000C6820" (* add $t5 $zero $t4 *);
        "214A0008" (* addi $t2 $t3 0x0008 *);
        "216B0006" (* addi $t3 $t2 0x0006 *);
      ]
  in
  let sim = Simulator.create ~config:Cyclesim.Config.trace_all (circuit_impl program scope) in
  let waves, sim = Waveform.create sim in

  for _i = 0 to n do
    Cyclesim.cycle sim
  done;

  waves

let () =
  let waves = testbench 15 in
  Hardcaml_waveterm_interactive.run ~wave_width:5 ~signals_width:30 waves