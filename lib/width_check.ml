open Hardcaml

module With_interface (I : Interface.S_Of_signal) (O : Interface.S_Of_signal) =
struct
  let check_widths circuit_impl i =
    I.Of_signal.assert_widths i;
    let out = circuit_impl i in
    O.Of_signal.assert_widths out;
    out
end
