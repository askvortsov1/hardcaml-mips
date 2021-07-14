open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = {
    sel_mem_for_reg_data : 'a;
    alu_result : 'a; [@bits 32]
    data_output : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { writeback_data : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

let circuit_impl (_scope : Scope.t) (input : _ I.t) =
  let writeback_data =
    mux2 input.sel_mem_for_reg_data input.data_output input.alu_result
  in
  { O.writeback_data }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"writeback" circuit_impl_exn input
