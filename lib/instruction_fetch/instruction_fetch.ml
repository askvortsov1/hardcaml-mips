open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = { pc : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { instruction : 'a; [@bits 32] next_pc : 'a [@bits 32] }
  [@@deriving sexp_of, hardcaml]
end

(*
In an actual computer, instruction memory would be actual memory,
and we would use Hardcaml's `multiport_memory` primitive to implement it.

Unfortunately, that primitive doesn't support initial values, so testing would
require either a complex sequence of `reset` logic or a physical RAM device.

The former would be messy and the latter beyond the scope of this project,
but we still don't want to hardcode a particular program as part of the design.
Instead, to keep things simple, we consider the program to be an input to the construction of our circuit.
*)
let instruction_memory program address =
  mux address (Program.to_signals program)

let create ~program (_scope : Scope.t) (i : _ I.t) =
  let address = srl i.pc 2 in
  let instruction = instruction_memory program address in
  { O.next_pc = i.pc +:. 4; O.instruction }

let hierarchical ~program (scope : Scope.t) (input : _ I.t) =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"instruction_fetch" (create ~program) input
