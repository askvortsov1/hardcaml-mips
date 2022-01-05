set_param board.repoPaths "boards/"
set output_dir "outputs/"

open_checkpoint $output_dir/post_synth.dcp

########################
# Various pin placements
########################

proc bind_port_to_pin { port_name pin_name } {
  set port       [get_ports "$port_name"]
  set pin        [get_board_part_pins "$pin_name"]
  set loc        [get_property LOC $pin]
  set iostandard [get_property IOSTANDARD $pin]

  set_property PACKAGE_PIN $loc        $port
  set_property IOSTANDARD  $iostandard $port
}

proc bind_ports_vector_to_pins {port_format pin_format n} {
  for { set i 0 } { $i < $n } { incr i } {
    set port_name  [format $port_format $i]
    set pin_name   [format $pin_format  $i]
    bind_port_to_pin $port_name $pin_name
  }
}

bind_ports_vector_to_pins "led_4bits\[%d\]"          "led_4bits_tri_o_%d" 4
bind_ports_vector_to_pins "led_rgb\[%d\]"            "rgb_led_tri_o_%d" 12
bind_ports_vector_to_pins "push_buttons_4bits\[%d\]" "push_buttons_4bits_tri_i_%d" 4
bind_port_to_pin          "usb_uart_rx"              "usb_uart_rxd"
bind_port_to_pin          "usb_uart_tx"              "usb_uart_txd"
bind_port_to_pin          "sys_clock"                "clk"
bind_port_to_pin          "reset"                    "reset"

bind_ports_vector_to_pins "eth_mii_rxd\[%d\]"        "eth_rxd_%d" 4
bind_port_to_pin          "eth_mii_rx_er"            "eth_rx_er"
bind_port_to_pin          "eth_mii_rx_dv"            "eth_rx_dv"
bind_port_to_pin          "eth_mii_rx_clk"           "eth_rx_clk"
bind_port_to_pin          "eth_mii_tx_clk"           "eth_tx_clk"

bind_port_to_pin          "eth_mii_tx_en"            "eth_tx_en"
bind_ports_vector_to_pins "eth_mii_txd\[%d\]"        "eth_txd_%d" 4

bind_port_to_pin          "mdc"                      "eth_mdc"

opt_design
place_design
phys_opt_design

write_checkpoint -force $output_dir/post_place
report_timing_summary -file $output_dir/post_place_timing_summary.rpt
