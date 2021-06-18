open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = { clock : 'a } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { instruction : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

let create (_scope : Scope.t) (_i : _ I.t) =
  { O.instruction = of_string "32'h0000000F" }

let hierarchical (scope : Scope.t) (input : _ I.t) =
  let module H = Hierarchy.In_scope (I)(O) in
  H.hierarchical ~scope ~name:"instruction_fetch" create input
