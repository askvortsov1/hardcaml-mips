open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = { clock : 'a } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { instruction : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

let circuit_impl (program : Program.t) (scope : Scope.t) (input : _ I.t) =
  let r = Reg_spec.create ~clock:input.clock () in

  (* Instruction Fetch Stage *)
  let pc = wire 32 in
  let pc_reg = reg_fb ~enable:vdd r ~w:32 (fun d -> d +:. 4) in
  let instruction_fetch =
    Instruction_fetch.hierarchical program scope { pc = pc_reg }
  in
  pc <== instruction_fetch.next_pc;

  (* Outputs *)
  { O.instruction = instruction_fetch.instruction }

let circuit_impl_exn program scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl program scope) input
