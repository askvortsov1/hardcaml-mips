open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = { clock : 'a; suffix : 'a } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { pc : 'a [@bits 5] } [@@deriving sexp_of, hardcaml]
end

let create (scope : Scope.t) (i : _ I.t) =
  let instruction_fetch =
    Instruction_fetch.hierarchical scope { clock = of_string "5'b11111" }
  in
  { O.pc = instruction_fetch.instruction.:[(3, 0)] @: i.clock }
