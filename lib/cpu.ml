open Hardcaml
open Hardcaml.Signal
module UA = Hardcaml_arty.User_application
module I = Hardcaml_arty.User_application.I

module O = struct
  type 'a t = {
    led_4bits : 'a; [@bits 4]
    led_rgb : 'a UA.Led_rgb.t list; [@length 4] [@rtlprefix "led_rgb_"]
    uart_tx : 'a Hardcaml_arty.Uart.Byte_with_valid.t; [@rtlprefix "uart_tx_"]
    ethernet : 'a UA.Ethernet.O.t; [@rtlprefix "eth_"]
    writeback_data : 'a; [@bits 32]
    writeback_pc : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

let rgb_off =
  {
    Hardcaml_arty.User_application.Led_rgb.r = of_bool false;
    g = of_bool false;
    b = of_bool false;
  }

let delay_test_addr = "32'hFFFFFFFF"

let circuit_impl program scope (input : t I.t) =
  let io_busy = wire 1 in
  let read_data = wire 32 in
  let datapath =
    Datapath.hierarchical program scope
      { Datapath.I.clock = input.clk_166; read_data; io_busy }
  in

  let using_delay_test_read =
    datapath.read_addr ==: of_string delay_test_addr
  in
  let using_delay_test_write =
    datapath.write_addr ==: of_string delay_test_addr
  in
  let delay_test_io =
    Delay_test_io.hierarchical scope
      {
        Delay_test_io.I.clock = input.clk_166;
        write_enable = datapath.write_enable;
        write_addr = datapath.write_addr;
        write_data = datapath.write_data;
        read_enable = using_delay_test_read &: datapath.read_enable;
        read_addr = datapath.read_addr;
      }
  in
  let delay_test_io_busy =
    using_delay_test_read |: using_delay_test_write &: delay_test_io.io_busy
  in
  let delay_test_read = (Signal.sresize using_delay_test_read 32) &: delay_test_io.read_data in

  let using_memory_read = ~:using_delay_test_read in
  let using_memory_write = ~:using_delay_test_write in
  let memory =
    Memory.hierarchical scope
      {
        Memory.I.clock = input.clk_166;
        write_enable = using_memory_write &: datapath.write_enable;
        write_addr = datapath.write_addr;
        write_data = datapath.write_data;
        read_enable = using_memory_read &: datapath.read_enable;
        read_addr = datapath.read_addr;
      }
  in
  let memory_busy = using_memory_read |: using_memory_write &: memory.io_busy in
  let memory_read = (Signal.sresize using_memory_read 32) &: memory.read_data in

  read_data <== (delay_test_read |: memory_read);
  io_busy <== (delay_test_io_busy |: memory_busy);

  {
    O.led_4bits = of_string "4'b0000";
    uart_tx = input.uart_rx;
    led_rgb = [ rgb_off; rgb_off; rgb_off; rgb_off ];
    ethernet = Hardcaml_arty.User_application.Ethernet.O.unused (module Signal);
    writeback_data = datapath.writeback_data;
    writeback_pc = datapath.writeback_pc;
  }
