# Changelog

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