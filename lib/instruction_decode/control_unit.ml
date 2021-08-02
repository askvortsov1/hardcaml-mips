open Hardcaml
open Hardcaml.Signal

module Instruction_format = struct
  let default = of_string "2'h0"

  let r_type = of_string "2'h1"

  let i_type = of_string "2'h2"

  let j_type = of_string "2'h3"
end

module Instruction_type = struct
  let default = of_int ~width:7 0

  (* Arithmetic *)
  let add = of_int ~width:7 10

  let addu = of_int ~width:7 11

  let addi = of_int ~width:7 12

  let addiu = of_int ~width:7 13

  let sub = of_int ~width:7 14

  let subu = of_int ~width:7 15

  (* Basic Logical *)
  let and_ = of_int ~width:7 20

  let andi = of_int ~width:7 21

  let or_ = of_int ~width:7 22

  let ori = of_int ~width:7 23

  let xor = of_int ~width:7 24

  let xori = of_int ~width:7 25

  (* Shifts *)
  let sll = of_int ~width:7 30

  let sllv = of_int ~width:7 31

  let srl = of_int ~width:7 32

  let srlv = of_int ~width:7 33

  let sra = of_int ~width:7 34

  let srav = of_int ~width:7 35

  (* Other I-Type *)
  let lui = of_int ~width:7 40

  (* Comparison *)
  let slt = of_int ~width:7 50

  let sltu = of_int ~width:7 51

  let slti = of_int ~width:7 52

  let sltiu = of_int ~width:7 53


  (* Memory *)
  let lw = of_int ~width:7 60

  let sw = of_int ~width:7 61

  (* Jump *)

  let j = of_int ~width:7 70

  let jr = of_int ~width:7 71

  let jal = of_int ~width:7 72

  (* Branch *)

  let bne = of_int ~width:7 80

  let beq = of_int ~width:7 81
end

module Alu_ops = struct
  let default = of_int ~width:5 0

  let noop = of_int ~width:5 1

  let add = of_int ~width:5 2

  let addu = of_int ~width:5 3

  let and_ = of_int ~width:5 4

  let lui = of_int ~width:5 5

  let or_ = of_int ~width:5 6

  let slt = of_int ~width:5 7

  let sltu = of_int ~width:5 8

  let sll = of_int ~width:5 9

  let sra = of_int ~width:5 10

  let srl = of_int ~width:5 11

  let sub = of_int ~width:5 12

  let subu = of_int ~width:5 13

  let xor = of_int ~width:5 14
end

module Pc_sel = struct
  module Enum = struct
    type t = 
    | Pc_incr
    | Jump_addr
    | Jump_reg
    | Branch_eq
    | Branch_neq
    [@@deriving sexp_of, compare, enumerate]
  end

  include Interface.Make_enums(Enum)
end

module Parsed_instruction = struct
  type 'a t = {
    rs : 'a; [@bits 5]
    rt : 'a; [@bits 5]
    rdest : 'a; [@bits 5]
    shamt : 'a; [@bits 5]
    se_imm : 'a; [@bits 32]
    alu_imm : 'a; [@bits 32]
    addr: 'a; [@bits 26]
  }
  [@@deriving sexp_of, hardcaml]
end

module Control_signals = struct
  type 'a t = {
    reg_write_enable : 'a;
    sel_mem_for_reg_data : 'a;
    mem_write_enable : 'a;
    sel_shift_for_alu : 'a;
    sel_imm_for_alu : 'a;
    stall_pc: 'a;
    jal: 'a;
    alu_control : 'a; [@bits width Alu_ops.default]
    pc_sel: 'a Pc_sel.Binary.t;
  }
  [@@deriving sexp_of, hardcaml]
end

module I = struct
  type 'a t = { instruction : 'a [@bits 32] } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    parsed_instruction : 'a Parsed_instruction.t;
    control_signals : 'a Control_signals.t;
  }
  [@@deriving sexp_of, hardcaml]
end

let rtype_classifier instr =
  let module T = Instruction_type in
  let funct = instr.:[(5, 0)] in
  let type_ = Always.Variable.wire ~default:T.default in
  Always.(
    compile
      [
        switch funct
          [
            (of_string "6'b100000", [ type_ <-- T.add ]);
            (of_string "6'b100001", [ type_ <-- T.addu ]);
            (of_string "6'b100011", [ type_ <-- T.subu ]);
            (of_string "6'b100100", [ type_ <-- T.and_ ]);
            (of_string "6'b100010", [ type_ <-- T.sub ]);
            (of_string "6'b100101", [ type_ <-- T.or_ ]);
            (of_string "6'b100110", [ type_ <-- T.xor ]);
            (of_string "6'b101010", [ type_ <-- T.slt ]);
            (of_string "6'b101011", [ type_ <-- T.sltu ]);
            (of_string "6'b000000", [ type_ <-- T.sll ]);
            (of_string "6'b000010", [ type_ <-- T.srl ]);
            (of_string "6'b000011", [ type_ <-- T.sra ]);
            (of_string "6'b000100", [ type_ <-- T.sllv ]);
            (of_string "6'b000110", [ type_ <-- T.srlv ]);
            (of_string "6'b000111", [ type_ <-- T.srav ]);
            (of_string "6'b001000", [ type_ <-- T.jr ]);
          ];
      ]);
  Always.Variable.value type_

let classifier instr =
  let module F = Instruction_format in
  let module T = Instruction_type in
  let opcode = instr.:[(31, 26)] in
  let format = Always.Variable.wire ~default:Instruction_format.default in
  let type_ = Always.Variable.wire ~default:Instruction_type.default in
  Always.(
    compile
      [
        switch opcode
          [
            ( of_string "6'b000000",
              [ format <-- F.r_type; type_ <-- rtype_classifier instr ] );
            (of_string "6'b001000", [ format <-- F.i_type; type_ <-- T.addi ]);
            (of_string "6'b001001", [ format <-- F.i_type; type_ <-- T.addiu ]);
            (of_string "6'b001100", [ format <-- F.i_type; type_ <-- T.andi ]);
            (of_string "6'b001101", [ format <-- F.i_type; type_ <-- T.ori ]);
            (of_string "6'b001110", [ format <-- F.i_type; type_ <-- T.xori ]);
            (of_string "6'b001111", [ format <-- F.i_type; type_ <-- T.lui ]);
            (of_string "6'b001010", [ format <-- F.i_type; type_ <-- T.slti ]);
            (of_string "6'b001011", [ format <-- F.i_type; type_ <-- T.sltiu ]);
            (of_string "6'b100011", [ format <-- F.i_type; type_ <-- T.lw ]);
            (of_string "6'b101011", [ format <-- F.i_type; type_ <-- T.sw ]);
            (of_string "6'b000010", [ format <-- F.j_type;  type_ <-- T.j]);
            (of_string "6'b000011", [ format <-- F.j_type;  type_ <-- T.jal]);
            (of_string "6'b000101", [ format <-- F.j_type;  type_ <-- T.bne]);
            (of_string "6'b000100", [ format <-- F.j_type;  type_ <-- T.beq]);

          ];
      ]);
  (Always.Variable.value format, Always.Variable.value type_)


let parser instr format type_ =
  let rt = instr.:[(20, 16)] in
  let rd = instr.:[(15, 11)] in
  let rdest = priority_select_with_default ~default:rd 
  [
    {
      With_valid.valid = type_ ==: Instruction_type.jal;
      value = of_string "5'd31";
    };
    {
      With_valid.valid = format ==: Instruction_format.i_type;
      value = rt;
    };
  ] in
  let ze_imm = uresize instr.:[(15, 0)] 32 in
  let se_imm = sresize instr.:[(15, 0)] 32 in
  let use_ze_for_imm =
    type_ ==: Instruction_type.addiu
    |: (type_ ==: Instruction_type.sltiu)
    |: (type_ ==: Instruction_type.lw)
    |: (type_ ==: Instruction_type.sw)
    |: (type_ ==: Instruction_type.andi)
    |: (type_ ==: Instruction_type.ori)
    |: (type_ ==: Instruction_type.xori)
    |: (type_ ==: Instruction_type.sll)
    |: (type_ ==: Instruction_type.srl)
    |: (type_ ==: Instruction_type.sra)
  in
  let alu_imm = mux2 use_ze_for_imm ze_imm se_imm in
  let module P = Parsed_instruction in
  {
    P.rs = instr.:[(25, 21)];
    rt;
    rdest;
    shamt = instr.:[(10, 6)];
    se_imm;
    alu_imm;
    addr = instr.:[(25, 0)];
  }

let type_to_alu_control type_ =
  let module O = Alu_ops in
  let module T = Instruction_type in
  let aluc = Always.Variable.wire ~default:Alu_ops.default in
  Always.(
    compile
      [
        switch type_
          [
            (* Arithmetic *)
            (T.add, [ aluc <-- O.add ]);
            (T.addu, [ aluc <-- O.addu ]);
            (T.addi, [ aluc <-- O.addu ]);
            (T.addiu, [ aluc <-- O.addu ]);
            (T.sub, [ aluc <-- O.sub ]);
            (T.subu, [ aluc <-- O.subu ]);
            (* Basic Logical *)
            (T.and_, [ aluc <-- O.and_ ]);
            (T.andi, [ aluc <-- O.and_ ]);
            (T.or_, [ aluc <-- O.or_ ]);
            (T.ori, [ aluc <-- O.or_ ]);
            (T.xor, [ aluc <-- O.xor ]);
            (T.xori, [ aluc <-- O.xor ]);
            (* Shifts *)
            (T.sll, [ aluc <-- O.sll ]);
            (T.sllv, [ aluc <-- O.sll ]);
            (T.sra, [ aluc <-- O.sra ]);
            (T.srav, [ aluc <-- O.sra ]);
            (T.srl, [ aluc <-- O.srl ]);
            (T.srlv, [ aluc <-- O.srl ]);
            (* Other I-Type *)
            (T.lui, [ aluc <-- O.lui ]);
            (* Comparison *)
            (T.slt, [ aluc <-- O.slt ]);
            (T.sltu, [ aluc <-- O.sltu ]);
            (T.slti, [ aluc <-- O.slt ]);
            (T.sltiu, [ aluc <-- O.sltu ]);
            (* Memory *)
            (T.lw, [ aluc <-- O.add ]);
            (T.sw, [ aluc <-- O.add ]);
            (* Jump *)
            (T.j, [ aluc <-- O.noop ]);
            (T.jal, [ aluc <-- O.noop ]);
            (T.jr, [ aluc <-- O.noop ]);
            (* Branch *)
            (T.bne, [ aluc <-- O.noop ]);
            (T.beq, [ aluc <-- O.noop ]);
          ];
      ]);
  Always.Variable.value aluc

let type_to_pc_sel type_ =
  let module PE = Pc_sel.Enum in
  let module PB = Pc_sel.Binary in
  let of_enum = PB.of_enum (module Signal) in
  PB.Of_signal.priority_select_with_default ~default:(of_enum PE.Pc_incr)
  [
    {
      With_valid.valid = (type_ ==: Instruction_type.j )|: (type_ ==: Instruction_type.jal);
      value = of_enum PE.Jump_addr;
    };
    {
      With_valid.valid = type_ ==: Instruction_type.jr;
      value = of_enum PE.Jump_reg;
    };
    {
      With_valid.valid = type_ ==: Instruction_type.beq;
      value = of_enum PE.Branch_eq;
    };
    {
      With_valid.valid = type_ ==: Instruction_type.bne;
      value = of_enum PE.Branch_neq;
    };
  ]

let control_core format type_ =
  let module F = Instruction_format in
  let module T = Instruction_type in
  let reg_write_enable =
    ((format ==: F.r_type) &: (type_ <>: T.jr)) |: (type_ ==: T.addi) |: (type_ ==: T.addiu)
    |: (type_ ==: T.andi) |: (type_ ==: T.ori) |: (type_ ==: T.xori)
    |: (type_ ==: T.lui) |: (type_ ==: T.slti) |: (type_ ==: T.sltiu)
    |: (type_ ==: T.lw) |: (type_ ==: T.jal)
  in
  let sel_mem_for_reg_data = type_ ==: T.lw in
  let mem_write_enable = type_ ==: T.sw in
  let sel_shift_for_alu =
    type_ ==: T.sll |: (type_ ==: T.srl) |: (type_ ==: T.sra)
  in
  let sel_imm_for_alu = format ==: F.i_type in
  let alu_control = type_to_alu_control type_ in
  let pc_sel = type_to_pc_sel type_ in
  let jal = type_ ==: T.jal in
  let module C = Control_signals in
  {
    C.reg_write_enable;
    sel_mem_for_reg_data;
    mem_write_enable;
    sel_shift_for_alu;
    sel_imm_for_alu;
    alu_control;
    (* This will get overriden in `instruction_decode` *)
    stall_pc = of_string "1'b0";
    pc_sel;
    jal;
  }

let circuit_impl (_scope : Scope.t) (input : _ I.t) =
  let instr_format, type_ = classifier input.instruction in
  let parsed_instruction = parser input.instruction instr_format type_ in
  let control_signals = control_core instr_format type_ in
  { O.parsed_instruction; control_signals }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"control_unit" circuit_impl_exn input
