open Hardcaml
open Mips
module MipsCircuit = Circuit.With_interface (Datapath.I) (Datapath.O)

let scope = Scope.create ()

let circuit =
  let bound_circuit_impl = Datapath.circuit_impl Program.sample scope in
  MipsCircuit.create_exn ~name:"datapath" bound_circuit_impl

let output_mode = Rtl.Output_mode.To_file("mips_datapath.v")

let () = Rtl.output ~output_mode ~database:(Scope.circuit_database scope) Verilog circuit
