let sample =
  Mips.Program.create
    [
      "20080004" (* addi t0 $0 4 *);
      "2009000A" (* addi t1 $0 10 *);
      "01095020" (* add t2 t0 t1 *);
    ]
