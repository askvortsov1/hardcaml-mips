

let () =
  Hardcaml_arty.Rtl_generator.generate ~instantiate_ethernet_mac:false (Mips_arty.Wrapper.circuit_impl Mips_arty.Program.sample)
    (To_channel Stdio.stdout)
