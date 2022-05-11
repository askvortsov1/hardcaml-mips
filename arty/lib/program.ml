let sample =
  Mips.Program.create
    [
      (* Altogether, store "arty" in ASCII in t0. *)
      "20080000" (* addi t0 $0 0 *);
      "3C086172" (* lui t0 0x6172 *);
      "35087479" (* ori t0 t0 0x7479 *);
    ]
