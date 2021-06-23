open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = { pc : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { instruction : 'a; [@bits 32] next_pc : 'a [@bits 32] }
  [@@deriving sexp_of, hardcaml]
end

let create (_scope : Scope.t) (i : _ I.t) =
  { O.next_pc = i.pc +:. 4; O.instruction = of_string "32'h014B4820" }

let hierarchical (scope : Scope.t) (input : _ I.t) =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"instruction_fetch" create input
