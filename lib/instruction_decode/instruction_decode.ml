open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = {
    clock : 'a;
    writeback_reg_write_enable : 'a;
    writeback_address : 'a; [@bits 5]
    writeback_data : 'a; [@bits 32]
    instruction : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    control_signals : 'a Control_unit.Control_signals.t;
    rs_val : 'a; [@bits 32]
    rt_val : 'a; [@bits 32]
    rdest : 'a; [@bits 5]
    ze_imm : 'a; [@bits 32]
    alu_imm : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

let delay_address_to_falling clock address = 
  let spec = Reg_spec.create ~clock:clock () in
  let spec_on_falling = Reg_spec.override ~clock_edge:Edge.Falling spec in
  reg ~enable:vdd spec_on_falling address

let regfile rs rt clock write_enable write_address write_data =
  let write_port =
    { write_clock = clock; write_address; write_enable; write_data }
  in
  let number_of_regs = 32 in
  let delay_address = delay_address_to_falling clock in
  let regs =
    multiport_memory number_of_regs ~write_ports:[|write_port|] ~read_addresses:[| delay_address rs; delay_address rt |]
  in
  (Array.get regs 0, Array.get regs 1)

let circuit_impl (scope : Scope.t) (input : _ I.t) =
  let control_unit =
    Control_unit.hierarchical scope { instruction = input.instruction }
  in
  let parsed = control_unit.parsed_instruction in
  let rs_val, rt_val =
    regfile parsed.rs parsed.rt input.clock input.writeback_reg_write_enable
      input.writeback_address input.writeback_data
  in
  {
    O.control_signals = control_unit.control_signals;
    rs_val;
    rt_val;
    rdest = parsed.rdest;
    ze_imm = parsed.ze_imm;
    alu_imm = parsed.alu_imm;
  }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"instruction_decode" circuit_impl_exn input
