# NCL-examples
A collection of Null Convention Logic examples, simulated and synthesized for FPGA

The ring.v example is Figure 3.11 "A three-cycle ring" from Karl
Fant's book "Logically Determined Design", generalized to N cycles.

The three-cycle ring (N=3) had a period of 1.05/2^27 s, corresponding
to an average propagation delay per stage of 2.608 ns.

N=4 had a period of 0.8/2^27 s, corresponding to an average
propagation delay per stage of 1.49 ns (notice, the overall oscilation
was _faster_ with a larger ring).

(N=5 was also at 0.8 s, so N=4 was best).

At N=129 I measured a period of 15/(2^27) s, corresponding to an
average propagation delay per stage of 0.866 ns.

The per-stage difference is (probably) explained by being bottlenecked
on backwards hole propagation.
