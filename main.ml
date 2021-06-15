open Hardcaml
open Mips

module MipsCircuit = Circuit.With_interface(Datapath.I)(Datapath.O)

let circuit = MipsCircuit.create_exn Datapath.create ~name:"datapath"

let () = Rtl.print Verilog circuit