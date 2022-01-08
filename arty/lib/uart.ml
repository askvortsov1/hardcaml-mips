open Hardcaml
open Hardcaml.Signal

module Word_with_valid = struct
  module Pre = struct
    include With_valid

    let t = 
      { valid = ("valid", 1)
      ; value = ("value", 32)
      }
    ;;
  end

  include Pre
  include Hardcaml.Interface.Make(Pre)
end

let num_start_bits = 1 
let num_data_bits = 8 
let num_stop_bits = 1
let bits_per_packet = num_start_bits + num_data_bits + num_stop_bits
let cycles_per_bit = 166_667_000 / 115_200 (* 166.667 MHz running at 115200 baud *)
let cycles_per_packet = bits_per_packet * cycles_per_bit

module Tx_buffer = struct 
  module States = struct
    type t =
      | S_idle
      | S_transmitting
    [@@deriving sexp_of, compare, enumerate]
  end
  let create ~clock ~clear (input: t Word_with_valid.t) =
    let spec = Reg_spec.create ~clock ~clear () in
    let reg_write_buffer = reg_fb spec ~enable:vdd ~w:32  (fun curr -> mux2 input.valid input.value curr) in

    let sm = Always.State_machine.create (module States) spec ~enable:vdd in
    let read_buffer_index = Always.Variable.reg spec ~enable:vdd ~width:2 in
    let tx_cycles_count = Always.Variable.reg spec ~enable:vdd ~width:(Base.Int.ceil_log2 cycles_per_packet) in

    let buffer_not_empty = (input.valid) ||: (read_buffer_index.value <>:. 0) in
    Always.(compile [
        sm.switch [
          S_idle, [
            when_ (buffer_not_empty) [
              sm.set_next S_transmitting
            ]
          ];
          S_transmitting, [
            tx_cycles_count <-- (tx_cycles_count.value +:. 1);
            when_ (tx_cycles_count.value ==:. cycles_per_packet) [
              tx_cycles_count <-- (of_int ~width:(Base.Int.ceil_log2 cycles_per_packet) 0);
              read_buffer_index <-- (read_buffer_index.value +:. 1);
              sm.set_next S_idle
            ];
          ];
        ]
      ]);
    {
      With_valid.valid = sm.is S_transmitting;
      value = reg_write_buffer;
    }
end
