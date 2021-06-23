open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = { clock : 'a } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { instruction : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

let create (scope : Scope.t) (_i : _ I.t) =
  let instruction_fetch =
    Instruction_fetch.hierarchical scope { pc = of_string "0" }
  in
  { O.instruction = instruction_fetch.instruction }
