open Hardcaml
open Hardcaml.Signal

type t = Signal.t list

let create program =
  program
  |> List.map (fun str -> "32'h" ^ str)
  |> List.map of_string

let to_signals program = program

let sample_strings =
  [
    "3c010000"; (* (00) main:   lui  $1, 0 *)
    "34240050"; (* (04)         ori  $4, $1, 50 *)
    "0c00001b"; (* (08) call:   jal  sum *)
    "20050004"; (* (0c) dslot1: addi $5, $0,  4 *)
    "ac820000"; (* (10) return: sw   $2, 0($4) *)
    "8c890000"; (* (14)         lw   $9, 0($4) *)
    "01244022"; (* (18)         sub  $8, $9, $4 *)
    "20050003"; (* (1c)         addi $5, $0,  3 *)
    "20a5ffff"; (* (20) loop2:  addi $5, $5, -1 *)
    "34a8ffff"; (* (24)         ori  $8, $5, 0xffff *)
    "39085555"; (* (28)         xori $8, $8, 0x5555 *)
    "2009ffff"; (* (2c)         addi $9, $0, -1 *)
    "312affff"; (* (30)         andi $10,$9,0xffff *)
    "01493025"; (* (34)         or   $6, $10, $9 *)
    "01494026"; (* (38)         xor  $8, $10, $9 *)
    "01463824"; (* (3c)    and  $7, $10, $6 *)
    "10a00003"; (* (40)         beq  $5, $0, shift *)
    "00000000"; (* (44) dslot2: nop *)
    "08000008"; (* (48)         j    loop2 *)
    "00000000"; (* (4c) dslot3: nop *)
    "2005ffff"; (* (50) shift:  addi $5, $0, -1 *)
    "000543c0"; (* (54)         sll  $8, $5, 15 *)
    "00084400"; (* (58)         sll  $8, $8, 16 *)
    "00084403"; (* (5c)         sra  $8, $8, 16 *)
    "000843c2"; (* (60)         srl  $8, $8, 15 *)
    "08000019"; (* (64) finish: j    finish *)
    "00000000"; (* (68) dslot4: nop *)
    "00004020"; (* (6c) sum:    add  $8, $0, $0 *)
    "8c890000"; (* (70) loop:   lw   $9, 0($4) *)
    "01094020"; (* (74) stall:  add  $8, $8, $9 *)
    "20a5ffff"; (* (78)         addi $5, $5, -1 *)
    "14a0fffc"; (* (7c)         bne  $5, $0, loop *)
    "20840004"; (* (80) dslot5: addi $4, $4,  4 *)
    "03e00008"; (* (84)         jr   $31 *)
    "00081000"; (* (88) dslot6: sll  $2, $8, 0 *)
  ]

let sample = create sample_strings
