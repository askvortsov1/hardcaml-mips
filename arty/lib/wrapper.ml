open Hardcaml
open Hardcaml_arty
open Signal

let rgb on = { User_application.Led_rgb.r = on; g = on; b = on }

(* Hardcoding this is not great, but there won't be a need to once we implement mmio. *)
let last_pc = "32'd8"

let display_val pc data =
  mux2
    (pc >=: of_string last_pc)
    (of_bool true @: data.:[(6, 0)])
    (of_string "8'h00")

let store_on_finished clk pc data =
  let spec = Reg_spec.create ~clock:clk () in
  let on_output_instr = pc ==: of_string last_pc in
  let data_reg =
    reg_fb spec ~enable:vdd ~w:8 (fun v ->
        mux2 on_output_instr data.:[(7, 0)] v)
  in
  mux2 on_output_instr data.:[(7, 0)] data_reg

let circuit_impl program _scope (input : _ User_application.I.t) =
  let datapath =
    Mips.Datapath.hierarchical program _scope { clock = input.clk_166 }
  in
  let uart_tx =
    { With_valid.valid = input.uart_rx.valid; value = input.uart_rx.value }
  in
  let finished_data =
    store_on_finished input.clk_166 datapath.writeback_pc
      datapath.writeback_data
  in
  let display = display_val datapath.writeback_pc finished_data in
  {
    User_application.O.led_4bits = display.:[(7, 4)];
    uart_tx;
    led_rgb =
      [ rgb display.:(0); rgb display.:(1); rgb display.:(2); rgb display.:(3) ];
    ethernet = User_application.Ethernet.O.unused (module Signal);
  }
