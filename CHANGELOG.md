# Changelog

## [0.10.0](https://github.com/askvortsov1/hardcaml-mips/compare/v0.9.0...v0.10.0)

- Outputs verilog code to a separate file, "mips_datapath.v"

## [0.9.0](https://github.com/askvortsov1/hardcaml-mips/compare/v0.8.0...v0.9.0)

- Added most MIPS instructions
  - Excluded mult/divide because we don't have hi/lo registers yet
  - Excluded jump, branch because we don't have next_pc selector logic yet
  - Excluded system calls / exception handling because we don't have an exception handling unit.
- Output `pc` in datapath
- Added some regfile-initializing instructions in the sample program
- Split `imm` parsed instructions into `ze_imm` (for eventual branching) and `alu_imm` (for ALU ops, is zero or sign extended depending on the instruction)

## [0.8.0](https://github.com/askvortsov1/hardcaml-mips/compare/v0.7.0...v0.8.0)

- Added memory and writeback stages. This completes the basic core of our CPU.
- Added write support to regfile, made it write-before-read to reduce hazards.

## [0.7.0](https://github.com/askvortsov1/hardcaml-mips/compare/v0.6.1...v0.7.0)

- Added instruction decode stage
  - Includes a 3 part control unit from v0.6.1
  - Created register file
- Added instruction execute stage
  - Created ALU with support for adds and subtracts
- Added tests for new components

## [0.6.1](https://github.com/askvortsov1/hardcaml-mips/compare/v0.5.2...v0.6.1)

- Added control unit.
  - Split into [3 components](https://excalidraw.com/#json=4874675947569152,f4jus3Ehk-DGZspiJAGUWw) for maintainability.

## [0.5.2](https://github.com/askvortsov1/hardcaml-mips/compare/v0.4.0...v0.5.2)

- Renamed circuit `create` functions to `circuit_impl`.
- Created a `Width_check.With_interface` functor with a `check_widths` function that checks input/output width compliance for circuit implementation.
- Instruction memory now returns noops when `pc` exceeds the length of the program to avoid unexpected effects.
- Standardized and cleaned up naming input
  - Inputs are type hinted in the circuit implementation functions, and derived functions use type inference for concision.

## [0.4.0](https://github.com/askvortsov1/hardcaml-mips/compare/v0.3.0...v0.4.0)

- Implemented feedback in datapath via register. This allows us to store and mutate the state of our system over time.
  
## [0.3.0](https://github.com/askvortsov1/hardcaml-mips/compare/v0.2.0...v0.3.0)

- Implemented `instruction_memory`. The program being executed is treated as an input to the entire processor.
  - See `instruction_fetch.ml` for an explanation of why we implemented instruction memory the way we did.
- Defined `Program` module to abstract away the concept of a program.

## [0.2.1](https://github.com/askvortsov1/hardcaml-mips/compare/v0.1.2...v0.2.0)

Proof of concept for module hierarchies:

- Started instruction fetch module
- No memory or registers yet, just constant output for now

## [0.1.2](https://github.com/askvortsov1/hardcaml-mips/tree/v0.1.2) 6/14/2021

Proof of concept:

- Created trivial circuit
- Added waveform-based expect test
- Built executable to print circuit in Verilog