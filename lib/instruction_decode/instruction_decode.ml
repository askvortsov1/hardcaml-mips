open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = { instruction : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    control_signals : 'a Control_unit.Control_signals.t;
    rs_val : 'a; [@bits 32]
    rt_val : 'a; [@bits 32]
    rdest : 'a; [@bits 5]
    imm : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

let regfile rs rt =
  (* We'll add write support when we get to the writeback stage. *)
  let write_port =
    {
      write_clock = gnd;
      write_address = (of_string "5'h1");
      write_enable = gnd;
      write_data = (of_string "32'h0");
    }
  in
  let number_of_regs = 32 in
  let regs =
    multiport_memory number_of_regs ~write_ports:[| write_port |]
      ~read_addresses:[| rs; rt |]
  in
  (Array.get regs 0, Array.get regs 1)

let circuit_impl (scope : Scope.t) (input : _ I.t) =
  let control_unit =
    Control_unit.hierarchical scope { instruction = input.instruction }
  in
  let parsed = control_unit.parsed_instruction in
  let rs_val, rt_val = regfile parsed.rs parsed.rt in
  {
    O.control_signals = control_unit.control_signals;
    rs_val;
    rt_val;
    rdest = parsed.rdest;
    imm = parsed.imm;
  }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"instruction_decode" circuit_impl_exn input
