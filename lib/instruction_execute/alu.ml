open Hardcaml
open Hardcaml.Signal

module I = struct
  type 'a t = {
    arg_a : 'a; [@bits 32]
    arg_b : 'a; [@bits 32]
    alu_control : 'a; [@bits 4]
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { result : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

let circuit_impl (_scope : Scope.t) (input : _ I.t) =
  let result = Always.Variable.wire ~default:(of_string "32'b0") in
  let module Op = Control_unit.Alu_ops in
  let a = input.arg_a in
  let b = input.arg_b in
  Always.(
    compile
      [
        switch input.alu_control
          [
            (Op.add, [ result <-- a +: b ]); (Op.subtract, [ result <-- a -: b ]);
          ];
      ]);

  { O.result = Always.Variable.value result }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"alu" circuit_impl_exn input
