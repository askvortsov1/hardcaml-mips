open Hardcaml
open Hardcaml.Signal

type t = Signal.t list

let create program =
  program
  |> List.map (fun str -> "32'h" ^ str)
  |> List.map of_string

let to_signals program = program

let sample_strings =
  [
    "21090007"; (* addi $t1 $t0 0x0007 *)
    "210A0008"; (* addi $t2 $t0 0x0008 *)
    "012A5820"; (* add $t3 $t1 $t2 *)
    "012A6020" (* add $t4 $t1 $t2 *)
  ]

let sample = create sample_strings
