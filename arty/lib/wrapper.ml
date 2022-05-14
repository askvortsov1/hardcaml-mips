open Hardcaml
open Signal
module User_application = Hardcaml_arty.User_application

let rgb on = { User_application.Led_rgb.r = on; g = on; b = on }
let circuit_impl _program _scope (input : _ User_application.I.t) =
  {
    User_application.O.led_4bits = of_string "4'b0000";
    uart_tx = input.uart_rx;
    led_rgb = [ rgb gnd; rgb gnd; rgb gnd; rgb gnd ];
    ethernet = User_application.Ethernet.O.unused (module Signal);
  }
