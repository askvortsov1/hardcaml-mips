type t = Hardcaml.Signal.t list

let create program = program
  |> List.map (fun str -> "32'h" ^ str)
  |> List.map Hardcaml.Signal.of_string

let to_signals program = program

let sample_strings = [
  "012A5820";  (* add $t3 $t1 $t2 *)
  "012A6020";  (* add $t4 $t1 $t2 *)
]

let sample = create sample_strings
