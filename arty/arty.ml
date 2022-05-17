open Hardcaml
open Signal
module User_application = Hardcaml_arty.User_application

let sample =
  Mips.Program.create
    [
      (* Altogether, store "arty" in ASCII in t0. *)
      "20080000" (* addi t0 $0 0 *);
      "3C086172" (* lui t0 0x6172 *);
      "35087479" (* ori t0 t0 0x7479 *);
    ]

let rgb on = { User_application.Led_rgb.r = on; g = on; b = on }

let circuit_impl _program _scope (input : _ User_application.I.t) =
  {
    User_application.O.led_4bits = of_string "4'b0000";
    uart_tx = input.uart_rx;
    led_rgb = [ rgb gnd; rgb gnd; rgb gnd; rgb gnd ];
    ethernet = User_application.Ethernet.O.unused (module Signal);
  }

let () =
  Hardcaml_arty.Rtl_generator.generate ~instantiate_ethernet_mac:false
    (circuit_impl sample) (To_channel Stdio.stdout)
