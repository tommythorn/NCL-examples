// 20230817-19
`default_nettype none

module th22n(output wire z, input init, input a, input b);
   // Alas, to use them in a combinatorial ring we must construct the LUT manually
   // reg zr; assign z = zr;
   // always @(*) if (init) zr = 0; else if (a == b) zr = a;

   // XXX The LUT inputs aren't equally fast, but I don't know which are faster
   //
   // I Z A B | Z'
   // --------+---
   // 0 0 0 0 | 0 majority 0
   // 0 0 0 1 | 0 no change
   // 0 0 1 0 | 0 no change
   // 0 0 1 1 | 1 majority 1
   // 0 1 0 0 | 0 majority 0
   // 0 1 0 1 | 1 no change
   // 0 1 1 0 | 1 no change
   // 0 1 1 1 | 1 majority 1
   // 1 X X X | 0 init value
   (* keep *) LUT4 #(.INIT(16'h00E8)) inst (.Z(z), .A(a), .B(b), .C(z), .D(init));
endmodule

module th22d(output wire z, input init, input a, input b);
   // Alas, to use them in a combinatorial ring we must construct the LUT manually
   // reg zr; assign z = zr;
   // always @(*) if (init) zr = 1; else if (a == b) zr = a;

   // XXX The LUT inputs aren't equally fast, but I don't know which are faster
   //
   // I Z A B | Z'
   // --------+---
   // 0 0 0 0 | 0 majority 0
   // 0 0 0 1 | 0 no change
   // 0 0 1 0 | 0 no change
   // 0 0 1 1 | 1 majority 1
   // 0 1 0 0 | 0 majority 0
   // 0 1 0 1 | 1 no change
   // 0 1 1 0 | 1 no change
   // 0 1 1 1 | 1 majority 1
   // 1 X X X | 1 init value
   (* keep *) LUT4 #(.INIT(16'hFFE8)) inst (.Z(z), .A(a), .B(b), .C(z), .D(init));
endmodule

// Annectotally, I counted 15 s for 2^27 counts, thus the 64*2+1 ring
// had a period of 111.6 ns, making each stage contribute ns. 0.865 ns
// Pretty good.

module top(input [6:0] btn, // btn[0] is normally high, the rest normally low
           output wire [7:0] led,
           output wifi_gpio0);

   // Tie GPIO0, keep board from rebooting
   assign wifi_gpio0 = 1;

   // NCL "reset"
   wire           init = !btn[0];

   // N-stage ring of N-1 th22n and one th22d
   // The lone th22d feeds q0, and the rest q
   parameter N = 4;  // Must be >= 3
   wire   [N-2:0] d, q, ack;
   wire           d0, q0, ack0;

   assign d0 = q[N-2];
   assign d = {q[N-3:0],q0};      // d[i] = q[i-1 modulo N]
   assign ack0 = ~q[0];
   assign ack = ~{q0,q[N-2:1]};    // ack[i] = q[i+1 modulo N]

   (* keep *) th22d th22_x         (.z(q0),.init(init), .a(d0), .b(ack0));
   (* keep *) th22n th22_0 [N-2:0] (.z(q), .init(init), .a(d),  .b(ack));

   reg flop; always @(posedge q[0]) flop <= ~flop;
   reg [26:0] cntr = 0; always @(posedge flop) cntr <= cntr + 1;
   assign led = cntr[26:26-7];
endmodule
