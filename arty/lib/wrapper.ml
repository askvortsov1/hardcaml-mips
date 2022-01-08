open Hardcaml
open Signal

let rgb on = { Hardcaml_arty.User_application.Led_rgb.r = on; g = on; b = on }

(* Hardcoding this is not great, but there won't be a need to once we implement mmio. *)
let last_pc = "32'd8"

let circuit_impl program _scope (input : _ Hardcaml_arty.User_application.I.t) =
  let datapath =
    Mips.Datapath.hierarchical program _scope { clock = input.clk_166 }
  in
  let uart_tx =
    Uart.Tx_buffer.create ~clock:input.clk_166
      ~clear:input.clear_n_166
      {
        With_valid.valid = datapath.writeback_pc ==: of_string last_pc;
        value = datapath.writeback_data;
      }
  in
  {
    Hardcaml_arty.User_application.O.led_4bits = of_string "4'b0000";
    uart_tx;
    led_rgb = [ rgb gnd; rgb gnd; rgb gnd; rgb gnd ];
    ethernet = Hardcaml_arty.User_application.Ethernet.O.unused (module Signal);
  }
