open Hardcaml

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

type I = {
  data: Word_with_valid.t
  ascii: Signal.t
}

type O = {
  data: Byte_with_valid.t
  sending: Signal.t
  buffer_empty: Signal.t
}

module Tx_buffer = struct 
  let create ~clock ~clear (input: Signal.t Word_with_valid.t) =
    reg read_buffer_index;
    reg write_buffer_index;

    if (input.valid) {
      buffer[write_buffer_index] = input.value;
      write_buffer_index += 4;
    }

    STATE_MACHINE:
      if IDLE {
        if (buffer not empty) {
          state <- TRANSMITTING;
        }
        output not valid
      }
      if TRANSMITTING {
        cycles_counter += 1;
        when (cycles_counter == cycles_per_packet) {
          cycles_counter = 0;
          state <- IDLE;
        }
        output valid, buffer[read_buffer_index];
      }
end
