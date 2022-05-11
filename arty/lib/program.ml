let sample =
  Mips.Program.create
    [
      "20080000" (* addi t0 $0 0 *);
      "3C086172" (* lui t0 0x6172 *);
      "35087479" (* ori t0 t0 0x7479 *);
    ]
