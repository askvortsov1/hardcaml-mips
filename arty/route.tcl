set_param board.repoPaths "boards/"
set output_dir "outputs/"

open_checkpoint $output_dir/post_place.dcp

route_design

write_checkpoint -force $output_dir/post_route
report_timing_summary -file $output_dir/post_route_timing_summary.rpt
report_bus_skew -file $output_dir/post_route_bus_skew.rpt
report_utilization -file $output_dir/post_route_utilization.rpt
write_bitstream  -force $output_dir/hardcaml_arty_top.bit
