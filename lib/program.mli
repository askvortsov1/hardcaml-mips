type t

(* The input should be a list of MIPS instructions in hexadecimal format *)
val create : string list -> t

val to_signals : t -> Hardcaml.Signal.t list

(* An example program instance used for testing *)
val sample : t
