open Hardcaml
open Hardcaml.Signal

(* Sample config for testing. *)
let sample_read_delay = 2
let sample_write_delay = 4
let sample_read_data = of_int ~width:32 5

module I = struct
  type 'a t = {
    clock : 'a; [@bits 1]
    write_enable : 'a; [@bits 1]
    write_addr : 'a; [@bits 32]
    write_data : 'a; [@bits 32]
    read_enable : 'a; [@bits 1]
    read_addr : 'a; [@bits 32]
  }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { io_busy : 'a; [@bits 1] read_data : 'a [@bits 32] }
  [@@deriving sexp_of, hardcaml]
end

module States = struct
  type t = Not_stalling | Stalling | Done_stalling
  [@@deriving sexp_of, compare, enumerate]
end

let stall_sm ~clock ~stall_cycles ?(done_output = of_int ~width:32 0)
    should_stall =
  let width = Base.Int.ceil_log2 stall_cycles in

  (* One cycle is taken while switching into the Stalling state.
   * The other is taken while switching out of it.
   *)
  let stall_cycles_sig = of_int ~width (stall_cycles - 2) in
  let r = Reg_spec.create ~clock () in
  let sm = Always.State_machine.create (module States) ~enable:vdd r in
  let remaining_cycles = Always.Variable.reg r ~enable:vdd ~width in
  Always.(
    compile
      [
        sm.switch
          [
            ( Not_stalling,
              [
                when_ should_stall
                  [
                    sm.set_next Stalling; remaining_cycles <-- stall_cycles_sig;
                  ];
              ] );
            ( Stalling,
              [
                remaining_cycles <-- remaining_cycles.value -:. 1;
                when_
                  (remaining_cycles.value <=:. 0)
                  [
                    sm.set_next Done_stalling;
                    remaining_cycles <-- stall_cycles_sig;
                  ];
              ] );
            (Done_stalling, [ sm.set_next Not_stalling ]);
          ];
      ]);
  (* If an I/O operation was just initiated, we are always stalling regardless of the state. *)
  let busy = should_stall |: sm.is Stalling &: ~:(sm.is Done_stalling) in
  let output = mux2 (sm.is Done_stalling) done_output (of_int ~width:32 0) in
  (busy, output)

let circuit_impl (_scope : Scope.t) (input : _ I.t) =
  let write_busy, _ =
    stall_sm ~clock:input.clock ~stall_cycles:sample_write_delay
      input.write_enable
  in
  let read_busy, read_data =
    stall_sm ~clock:input.clock ~stall_cycles:sample_read_delay
      ~done_output:sample_read_data input.read_enable
  in
  let io_busy = write_busy |: read_busy in
  { O.read_data; io_busy }

let hierarchical scope input =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ~scope ~name:"delay_test_io" circuit_impl input
