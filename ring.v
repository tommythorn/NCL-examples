// 20230817-19
`default_nettype none
module top(input [6:0] btn, // btn[0] is normally high, the rest normally low
           output wire [7:0] led,
           output wifi_gpio0);

   // Tie GPIO0, keep board from rebooting
   assign wifi_gpio0 = 1;

   // NCL "reset"
   wire           init = !btn[0];

   // N-stage ring of N-1 th22ni and one th22d
   // The lone th22di feeds q0, and the rest q
   parameter N = 4;  // Must be >= 3
   wire   [N-2:0] d, q, ack;
   wire           d0, q0, ack0;

   assign d0 = q[N-2];
   assign d = {q[N-3:0],q0};      // d[i] = q[i-1 modulo N]
   assign ack0 = q[0];
   assign ack = {q0,q[N-2:1]};    // ack[i] = q[i+1 modulo N]

   (* keep *) th22di th22_x         (.z(q0),.init(init), .a(d0), .ack(ack0));
   (* keep *) th22ni th22_0 [N-2:0] (.z(q), .init(init), .a(d),  .ack(ack));

   reg flop; always @(posedge q[0]) flop <= ~flop;
   reg [26:0] cntr = 0; always @(posedge flop) cntr <= cntr + 1;
   assign led = cntr[26:26-7];
endmodule
