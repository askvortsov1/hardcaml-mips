open Hardcaml.Signal
module UA = Hardcaml_arty.User_application

let rgb_off =
  {
    Hardcaml_arty.User_application.Led_rgb.r = of_bool false;
    g = of_bool false;
    b = of_bool false;
  }

let sample =
  Mips.Program.create
    [
      "3C10FFFF" (* (0) lui $s0 0xFFFF *);
      "3610FFFE" (* (4) ori $s0 $s0 0xFFFE *);
      "20110030" (* (8) addi $s1 $zero 0x0030 *);
      "356B3A20" (* (C) ori $t3 $t3 0x3A20 *);
      "AE0B0000" (* (10) sw $t3 0x0000 $s0 *);
      "8E080000" (* (14) lw $t0 0x0000 $s0 *);
      "AE080000" (* (18) sw $t0 0x0000 $s0 *);
      "3C0B0A00" (* (1C) lui $t3 0x0A00 *);
      "356B0000" (* (20) ori $t3 $t3 0x0000 *);
      "AE0B0000" (* (24) sw $t3 0x0000 $s0 *);
      "3C0B2332" (* (28) lui $t3 0x2332 *);
      "356B3A20" (* (2C) ori $t3 $t3 0x3A20 *);
      "AE0B0000" (* (30) sw $t3 0x0000 $s0 *);
      "8E090000" (* (34) lw $t1 0x0000 $s0 *);
      "AE090000" (* (38) sw $t1 0x0000 $s0 *);
      "00084602" (* (3C) srl $t0 $t0 0x0018 *);
      "00094E02" (* (40) srl $t1 $t1 0x0018 *);
      "01114022" (* (44) sub $t0 $t0 $s1 *);
      "01314822" (* (48) sub $t1 $t1 $s1 *);
      "01095020" (* (4C) add $t2 $t0 $t1 *);
      "01515020" (* (50) add $t2 $t2 $s1 *);
      "3C0B0A00" (* (54) lui $t3 0x0A00 *);
      "356B0000" (* (58) ori $t3 $t3 0x0000 *);
      "AE0B0000" (* (5C) sw $t3 0x0000 $s0 *);
      "3C0B414E" (* (60) lui $t3 0x414E *);
      "356B533A" (* (64) ori $t3 $t3 0x533A *);
      "AE0B0000" (* (68) sw $t3 0x0000 $s0 *);
      "AE0A0000" (* (6C) sw $t2 0x0000 $s0 *);
      "3C0B0A00" (* (70) lui $t3 0x0A00 *);
      "356B0000" (* (74) ori $t3 $t3 0x0000 *);
      "AE0B0000" (* (78) sw $t3 0x0000 $s0 *);
    ]

let circuit program scope input =
  let cpu = Mips.Cpu.circuit_impl program scope input in
  {
    UA.O.uart_tx = cpu.uart_tx;
    ethernet = cpu.ethernet;
    led_4bits = cpu.writeback_pc.:[(31, 28)];
    led_rgb = [ rgb_off; rgb_off; rgb_off; rgb_off ];
  }

let () =
  Hardcaml_arty.Rtl_generator.generate ~instantiate_ethernet_mac:false    
    (circuit sample) (To_channel Stdio.stdout)
