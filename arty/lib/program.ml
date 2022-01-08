let sample =
  Mips.Program.create
    [
      "20080020" (* addi t0 $0 32 *);
      "2009000B" (* addi t1 $0 11 *);
      "01095020" (* add t2 t0 t1 *);
    ]
