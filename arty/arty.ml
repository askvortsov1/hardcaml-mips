open Hardcaml
open Hardcaml_arty
open Signal

let rgb_off =
  {
    User_application.Led_rgb.r = of_string "0";
    g = of_string "0";
    b = of_string "0";
  }

let create _scope (input : _ User_application.I.t) =
  let uart_tx =
    { With_valid.valid = input.uart_rx.valid; value = input.uart_rx.value }
  in
  {
    User_application.O.led_4bits = of_string "4'b1111";
    uart_tx;
    led_rgb = [ rgb_off; rgb_off; rgb_off; rgb_off ];
    ethernet = User_application.Ethernet.O.unused (module Signal);
  }

let () =
  Hardcaml_arty.Rtl_generator.generate ~instantiate_ethernet_mac:false create
    (To_channel Stdio.stdout)
