open Hardcaml
open Hardcaml.Signal

module Data_options = struct
  type 'a t = {
    reg_value : 'a; [@bits 32]
    e_alu_output : 'a; [@bits 32]
    m_alu_output : 'a; [@bits 32]
    m_data_output : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

module Controls = struct
  type 'a t = {
    e_stalled : 'a;
    e_sel_mem_for_reg_data : 'a;
    m_sel_mem_for_reg_data : 'a;
    e_reg_write_enable : 'a;
    m_reg_write_enable : 'a;
  }
  [@@deriving sexp_of, hardcaml]
end

module I = struct
  type 'a t = {
    options : 'a Data_options.t;
    controls : 'a Controls.t;
    source : 'a; [@bits 5]
    e_dest : 'a; [@bits 5]
    m_dest : 'a; [@bits 5]
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { forward_data : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

let circuit_impl (_scope : Scope.t) (input : _ I.t) =
  let opt = input.options in
  let ctrl = input.controls in
  let forward_data =
    priority_select_with_default ~default:opt.reg_value
      [
        {
          With_valid.valid =
            (* The last instruction wrote to this register, and was NOT a lw, and WAS NOT stalled. *)
            ctrl.e_reg_write_enable
            &: (input.source ==: input.e_dest)
            &: ~:(ctrl.e_sel_mem_for_reg_data)
            &: ~:(ctrl.e_stalled);
          value = opt.e_alu_output;
        };
        {
          With_valid.valid =
            (* The 2nd to last instruction wrote to this register, and was an lw. *)
            ctrl.m_reg_write_enable
            &: (input.source ==: input.m_dest)
            &: ctrl.m_sel_mem_for_reg_data;
          value = opt.m_data_output;
        };
        {
          (* The 2nd to last instruction wrote to this register *)
          With_valid.valid =
            ctrl.m_reg_write_enable &: (input.source ==: input.m_dest);
          value = opt.m_alu_output;
        };
      ]
  in
  { O.forward_data }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"forwarding_unit" circuit_impl_exn input
