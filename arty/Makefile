.PHONY:  ../_build/default/arty/arty.exe

../_build/default/arty/arty.exe:
	dune build arty.exe

hardcaml_arty_top.v: ../_build/default/arty/arty.exe
	$< >$@

outputs/post_synth.dcp: synth.tcl hardcaml_arty_top.v
	vivado -nojournal -mode batch -source synth.tcl -log outputs/synth.log

outputs/post_place.dcp: place.tcl outputs/post_synth.dcp
	vivado -nojournal -mode batch -source place.tcl -log outputs/place.log

outputs/hardcaml_arty_top.bit outputs/post_route.dcp: route.tcl outputs/post_place.dcp
	vivado -nojournal -mode batch -source route.tcl -log outputs/route.log
	rm -f usage_statistics_webtalk.html usage_statistics_webtalk.xml

clean:
	rm -f outputs/*
