# NCL-examples
A collection of Null Convention Logic examples, simulated and synthesized for FPGA

The ring.v example is Figure 3.11 "A three-cycle ring" from Karl
Fant's book "Logically Determined Design", generalized to N cycles.

N=4 had a period of 0.54/2^27 s, corresponding to an oscillation
frequency of 248.6 MHz and an average propagation delay per stage of
1.00 ns.

An earlier experiment with a more expensive gate measure an N=129 ring
at a period of 15/(2^27) s, corresponding to an average propagation
delay per stage of 0.866 ns.
