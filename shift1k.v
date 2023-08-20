/*
 * 20230817
 *
 * Simplest possible (non-trivial) Null-Convention Logic (NCL)
 * example: a ring of three stages
 *
 * but with less initialization
 *
 */
`default_nettype none
module pipeline(input  wire init,
                output wire q0,
                output wire qk0);

   parameter                N = 1000;
   wire [N-1:0]             q;
   wire [N-1:0]             qk;

   assign q0 = q[0];
   assign qk0 = qk[0];
   genvar                   i;

   // Each stage takes the acknowledgement from next stage and data
   // from the previous stage

   // First
   th22i #(0) th22_0(.init(init), .A(q[N-1]), .B(qk[1]), .Q(q[0]));
   assign qk[0] = !q[0];

   // Middle
   for (i = 1; i < N-1; i = i + 1) begin
      th22 th22_1(.A(q[i-1]), .B(qk[i+1]), .Q(q[i]));
      assign qk[i] = !q[i];
   end

   // Last
   th22i #(1) th22_2(.init(init), .A(q[N-2]), .B(qk[0]), .Q(q[N-1]));
   assign qk[N-1] = !q[N-1];
endmodule

// Threshold 2-of-2 gate, also known as Muller's C-element
module th22(input A, input B, output reg Q
`ifndef FPGA
 = 0
`endif
);
   // We can implement this with a majority gate with feedback
   //sky130_fd_sc_hd__maj3_1 maj(.X(Q), .A(A), .B(B), .C(Q));

   always @(*)
     if (A & B)
       Q <= #1 1;
     else if (!A & !B)
       Q <= #1 0;
endmodule

// Threshold 2-of-2 gate, with initialization
module th22i
    #(parameter INITIAL = 0) (
      input      init,
      input      A,
      input      B,
      output reg Q);
   always @(*)
     if (init)
       Q <= #1 INITIAL;
     else if (A & B)
       Q <= #1 1;
     else if (!A & !B)
       Q <= #1 0;
endmodule


`ifdef FPGA
module top(input  wire clock, output wire [2:0] td);
   wire q, qk;
   reg [10:0]                count_down = 0;
   always @(posedge clock) if (!count_down[10]) count_down <= count_down - 1;
   wire                      init = !count_down[10];
   reg                       led = 0;
   always @(posedge q) led <= !led;
   assign td = {3{led}};
   pipeline pipeline_1(init, q, qk);
endmodule
`else
module tb;
   reg init = 0;
   wire q, qk;

   pipeline pipeline_1(init, q, qk);


   initial begin
      $dumpfile("pipeline.vcd");
      $dumpvars(0, pipeline_1);



      #10 init = 1;
      #21 init = 0;
      #1000 $finish;
   end
endmodule
`endif
