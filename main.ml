open Hardcaml
open Mips

module MipsCircuit = Circuit.With_interface(Datapath.I)(Datapath.O)

let scope = Scope.create ()

let circuit = 
  let bound_create =
  Datapath.create scope in
  MipsCircuit.create_exn ~name:"datapath" bound_create 

let () = Rtl.print ~database:(Scope.circuit_database scope) Verilog circuit