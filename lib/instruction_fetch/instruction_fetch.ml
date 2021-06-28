open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = { pc : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { instruction : 'a; [@bits 32] next_pc : 'a [@bits 32] }
  [@@deriving sexp_of, hardcaml]
end

(* In an actual computer, instruction memory would be actual memory,
 * and we would use Hardcaml's `multiport_memory` primitive to implement it.
 * 
 * Unfortunately, that primitive doesn't support initial values, so testing would
 * require either a complex sequence of `reset` logic or a physical RAM device.
 * 
 * The former would be messy and the latter beyond the scope of this project,
 * but we still don't want to hardcode a particular program as part of the design.
 * Instead, to keep things simple, we consider the program to be an input to our Hardcaml CPU.
 *)
let instruction_memory program address =
  (* When the selector > length inputs, Hardcaml's mux will just repeat the last element.
   * To avoid unexpected effects if `pc` goes beyond the length of our program,
   * we append a noop to our program. *)
  let program_signals = Program.to_signals program @ [ of_string "32'h0" ] in
  mux address program_signals

let circuit_impl (program : Program.t) (_scope : Scope.t) (input : _ I.t) =
  let address = srl input.pc 2 in
  let instruction = instruction_memory program address in
  { O.next_pc = input.pc +:. 4; O.instruction }

let circuit_impl_exn program scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl program scope) input

let hierarchical program scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"instruction_fetch" (circuit_impl_exn program)
    input
