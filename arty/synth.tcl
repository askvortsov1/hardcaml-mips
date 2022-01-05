set_param board.repoPaths "boards/"

create_project -in_memory -part xc7a35ticsg324-1L
set_property board_part digilentinc.com:arty-a7-35:part0:1.0 [current_project]
set output_dir "./outputs"

exec rm -rf outputs/ips
exec cp -r ips/ outputs/ips
read_ip -verbose outputs/ips/design_1_clk_wiz_0_0/design_1_clk_wiz_0_0.xci

# TODO(fyquah): It is unfortunate that we need to comment this out by hand. Our
# RTL generator should know that the thernet mac isn't used, and hence
# shouldn't be read here. This can be fixed by generating tcl files.
# read_ip      -verbose ips/hardcaml_arty_tri_mode_ethernet_mac_0/hardcaml_arty_tri_mode_ethernet_mac_0.xci
read_verilog hardcaml_arty_top.v

upgrade_ip [get_ips]
set_property generate_synth_checkpoint false [get_files outputs/ips/design_1_clk_wiz_0_0/design_1_clk_wiz_0_0.xci]
# set_property generate_synth_checkpoint false [get_files ips/hardcaml_arty_tri_mode_ethernet_mac_0/hardcaml_arty_tri_mode_ethernet_mac_0.xci]
generate_target all [get_ips]
validate_ip [get_ips]

synth_design -top hardcaml_arty_top
write_checkpoint -force "${::output_dir}/post_synth.dcp"
