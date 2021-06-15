open Hardcaml.Signal

module I = struct
  type 'a t = { clock : 'a; suffix: 'a } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { pc : 'a [@bits 5] } [@@deriving sexp_of, hardcaml]
end

let create (i : _ I.t) = { O.pc = (of_string "1111") @: i.suffix }
