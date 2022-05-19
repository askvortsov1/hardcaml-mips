open Hardcaml
open Hardcaml.Signal

module Word_with_valid = struct
  module Pre = struct
    include With_valid

    let t = { valid = ("valid", 1); value = ("value", 32) }
  end

  include Pre
  include Hardcaml.Interface.Make (Pre)
end

let num_start_bits = 1
let num_data_bits = 8
let num_stop_bits = 1
let bits_per_packet = num_start_bits + num_data_bits + num_stop_bits

let cycles_per_bit =
  166_667_000 / 115_200 (* 166.667 MHz running at 115200 baud *)

let cycles_per_packet = bits_per_packet * cycles_per_bit
let newline_hex = 0x0A

module Rx_buffer = struct
  module States = struct
    type t = S_idle | S_wait_next_byte | S_finished
    [@@deriving sexp_of, compare, enumerate]
  end

  let create ~clock ~read_enable
      (input : t Hardcaml_arty.Uart.Byte_with_valid.t) =
    let spec = Reg_spec.create ~clock () in

    let sm = Always.State_machine.create (module States) spec ~enable:vdd in

    (* This will never be true when sm.is S_finished,
     * b/c input.valid is only vdd for one cycle/packet
     *)
    let should_update_buffer =
      input.valid &: (sm.is S_wait_next_byte |: read_enable)
    in
    let buffer_index = Always.Variable.reg spec ~enable:vdd ~width:2 in
    let reg_read_buffer =
      reg_fb spec ~enable:vdd ~width:32 ~f:(fun curr ->
          let curr_byte_word = uresize input.value 32 in
          let new_buffer_val =
            mux buffer_index.value
              [
                curr &: of_string "32'h00000000" |: sll curr_byte_word 24;
                curr &: of_string "32'hFF000000" |: sll curr_byte_word 16;
                curr &: of_string "32'hFFFF0000" |: sll curr_byte_word 8;
                curr &: of_string "32'hFFFFFF00" |: curr_byte_word;
              ]
          in
          mux2 should_update_buffer new_buffer_val curr)
    in

    Always.(
      compile
        [
          sm.switch
            [
              ( S_idle,
                [
                  when_ read_enable
                    [
                      when_ input.valid
                        [
                          buffer_index <-- buffer_index.value +:. 1;
                        ];
                      sm.set_next S_wait_next_byte;
                    ];
                ] );
              ( S_wait_next_byte,
                [
                  when_ input.valid
                    [
                      buffer_index <-- buffer_index.value +:. 1;
                      when_
                        (buffer_index.value ==:. 3
                        |: (input.value ==: of_int ~width:8 newline_hex))
                        [ sm.set_next S_finished ];
                    ];
                ] );
              (S_finished, [ buffer_index <--. 0; sm.set_next S_idle ]);
            ];
        ]);
    let read_busy =
      ~:(sm.is S_finished) &: (sm.is S_wait_next_byte |: read_enable)
    in
    ({ With_valid.valid = sm.is S_finished; value = reg_read_buffer }, read_busy)
end

module Tx_buffer = struct
  module States = struct
    type t = S_idle | S_start_of_byte | S_transmitting_byte | S_finished
    [@@deriving sexp_of, compare, enumerate]
  end

  let create ~clock (input : t Word_with_valid.t) =
    let spec = Reg_spec.create ~clock () in

    let reg_write_buffer =
      reg_fb spec ~enable:vdd ~width:32 ~f:(fun curr ->
          mux2 input.valid input.value curr)
    in

    let cycles_width = Base.Int.ceil_log2 cycles_per_packet + 2 in

    let sm = Always.State_machine.create (module States) spec ~enable:vdd in
    let read_buffer_index = Always.Variable.reg spec ~enable:vdd ~width:2 in
    let tx_cycles_count =
      Always.Variable.reg spec ~enable:vdd ~width:cycles_width
    in

    Always.(
      compile
        [
          sm.switch
            [
              ( S_idle,
                [
                  when_ input.valid
                    [ read_buffer_index <--. 0; sm.set_next S_start_of_byte ];
                ] );
              ( S_start_of_byte,
                [
                  tx_cycles_count <-- of_int ~width:cycles_width 0;
                  sm.set_next S_transmitting_byte;
                ] );
              ( S_transmitting_byte,
                [
                  tx_cycles_count <-- tx_cycles_count.value +:. 1;
                  when_
                    (tx_cycles_count.value >=:. cycles_per_packet)
                    [
                      read_buffer_index <-- read_buffer_index.value +:. 1;
                      if_
                        (read_buffer_index.value ==:. 3)
                        [ sm.set_next S_finished ]
                        [ sm.set_next S_start_of_byte ];
                    ];
                ] );
              (S_finished, [ read_buffer_index <--. 0; sm.set_next S_idle ]);
            ];
        ]);
    let value =
      mux read_buffer_index.value
        [
          reg_write_buffer.:[(31, 24)];
          reg_write_buffer.:[(23, 16)];
          reg_write_buffer.:[(15, 8)];
          reg_write_buffer.:[(7, 0)];
        ]
    in
    let write_busy =
      sm.is S_start_of_byte |: sm.is S_transmitting_byte
      |: (input.valid &: ~:(sm.is S_finished))
    in
    ({ With_valid.valid = sm.is S_start_of_byte; value }, write_busy)
end

module I = struct
  type 'a t = {
    clock : 'a; [@bits 1]
    write_enable : 'a; [@bits 1]
    write_addr : 'a; [@bits 32]
    write_data : 'a; [@bits 32]
    read_enable : 'a; [@bits 1]
    read_addr : 'a; [@bits 32]
    uart_rx : 'a Hardcaml_arty.Uart.Byte_with_valid.t; [@rtlprefix "rx_"]
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    io_busy : 'a; [@bits 1]
    read_data : 'a; [@bits 32]
    uart_tx : 'a Hardcaml_arty.Uart.Byte_with_valid.t; [@rtlprefix "tx_"]
  }
  [@@deriving sexp_of, hardcaml]
end

let circuit_impl (_scope : Scope.t) (input : _ I.t) =
  let tx, write_busy =
    Tx_buffer.create ~clock:input.clock
      { With_valid.value = input.write_data; valid = input.write_enable }
  in
  let rx, read_busy =
    Rx_buffer.create ~clock:input.clock ~read_enable:input.read_enable
      input.uart_rx
  in
  let io_busy = write_busy |: read_busy in
  { O.read_data = rx.value; io_busy; uart_tx = tx }

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"uart" circuit_impl input
