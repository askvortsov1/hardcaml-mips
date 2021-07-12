open Hardcaml
open Hardcaml.Signal

module Parsed_instruction = struct
  type 'a t = {
    rs : 'a; [@bits 5]
    rt : 'a; [@bits 5]
    rdest : 'a; [@bits 5]
    shamt : 'a; [@bits 5]
    imm : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

module Control_signals = struct
  type 'a t = {
    reg_write_enable : 'a;
    sel_mem_for_reg_data : 'a;
    mem_write_enable : 'a;
    sel_imm_for_alu : 'a;
    alu_control : 'a; [@bits 4]
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

module Instruction_format = struct
  let default = of_string "2'h0"

  let r_type = of_string "2'h1"

  let i_type = of_string "2'h2"
end

module Instruction_type = struct
  let default = of_string "6'h0"

  let add = of_string "6'h1"

  let sub = of_string "6'h2"

  let lw = of_string "6'h3"

  let sw = of_string "6'h4"
end

exception Invalid_instruction

let rtype_classifier instr =
  let funct = instr.:[(5, 0)] in
  let instr_type = Always.Variable.wire ~default:Instruction_type.default in
  Always.(
    compile
      [
        switch funct
          [
            (of_string "6'b100000", [ instr_type <-- Instruction_type.add ]);
            (of_string "6'b100010", [ instr_type <-- Instruction_type.sub ]);
          ];
      ]);
  Always.Variable.value instr_type

let classifier instr =
  let opcode = instr.:[(31, 26)] in
  let format = Always.Variable.wire ~default:Instruction_format.default in
  let instr_type = Always.Variable.wire ~default:Instruction_type.default in
  Always.(
    compile
      [
        switch opcode
          [
            ( of_string "6'b000000",
              [
                format <-- Instruction_format.r_type;
                instr_type <-- rtype_classifier instr;
              ] );
            ( of_string "6'b100011",
              [
                format <-- Instruction_format.i_type;
                instr_type <-- Instruction_type.lw;
              ] );
            ( of_string "6'b101011",
              [
                format <-- Instruction_format.i_type;
                instr_type <-- Instruction_type.sw;
              ] );
          ];
      ]);
  (Always.Variable.value format, Always.Variable.value instr_type)

let parser instr format =
  let rt = instr.:[(20, 16)] in
  let rd = instr.:[(15, 11)] in
  let rdest = mux2 (format ==: Instruction_format.r_type) rd rt in
  let module P = Parsed_instruction in
  {
    P.rs = instr.:[(25, 21)];
    rt;
    rdest;
    shamt = instr.:[(10, 6)];
    imm = sresize instr.:[(15, 0)] 32;
  }

module Alu_ops = struct
  let default = of_string "4'h0"
  let noop =  of_string "4'h1"
  let add = of_string "4'h2"
  let subtract = of_string "4'h3"
end

let type_to_alu_control instr_type = 
  let aluc = Always.Variable.wire ~default:Alu_ops.default in
  Always.(
    compile
    [ switch instr_type 
      [
        Instruction_type.add, [aluc <-- Alu_ops.add];
        Instruction_type.sub, [aluc <-- Alu_ops.subtract];
        Instruction_type.lw, [aluc <-- Alu_ops.add];
        Instruction_type.sw, [aluc <-- Alu_ops.add];
      ];

    ]);
    Always.Variable.value aluc

let control_core format instr_type =
  let reg_write_enable =
    format ==: Instruction_format.r_type |: (instr_type ==: Instruction_type.lw)
  in
  let sel_mem_for_reg_data = instr_type ==: Instruction_type.lw in
  let mem_write_enable = instr_type ==: Instruction_type.sw in
  let sel_imm_for_alu = format ==: Instruction_format.i_type in
  let alu_control = type_to_alu_control instr_type in
  let module C = Control_signals in
  {
    C.reg_write_enable;
    sel_mem_for_reg_data;
    mem_write_enable;
    sel_imm_for_alu;
    alu_control;
  }

let circuit_impl (_scope : Scope.t) (input : _ I.t) =
  let instr_format, instr_type = classifier input.instruction in
  let parsed_instruction = parser input.instruction instr_format in
  let control_signals = control_core instr_format instr_type in
  { O.parsed_instruction; control_signals }

let circuit_impl_exn scope input =
  let module W = Width_check.With_interface (I) (O) in
  W.check_widths (circuit_impl scope) input

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"control_unit" circuit_impl_exn input
