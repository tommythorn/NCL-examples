/*
 * Simplest possible (non-trivial) Null-Convention Logic (NCL)
 * example: a ring of three stages
 *
 */
`default_nettype none
module tb;
   reg init = 0;
   wire q;
   wire qk;
   
   pipeline pipeline_1(init, q, qk);


   initial begin
      $dumpfile("pipeline.vcd");
      $dumpvars(0, pipeline_1);



      #10 init = 1;
      #21 init = 0;
      #1000 $finish;
   end
endmodule

module pipeline(input  wire init,
		output wire q0,
		output wire qk0);

   wire				  q1, q2;
   wire				  qk1, qk2;

   // Each stage takes the acknowledgement from next stage and data
   // from the previous stage
   th22i #(0) th22_0(.init(init), .A(q2), .B(qk1), .Q(q0));
   assign qk0 = !q0;   
   th22i #(1) th22_1(.init(init), .A(q0), .B(qk2), .Q(q1));
   assign qk1 = !q1;   
   th22i #(0) th22_2(.init(init), .A(q1), .B(qk0), .Q(q2));
   assign qk2 = !q2;   
endmodule

// Threshold 1-of-2 gate, also known as "or"
module th12(input A, input B, output reg Q);
   always @(*) Q = #2 A | B;
endmodule

// Threshold 2-of-2 gate, also known as Muller's C-element
module th22(input A, input B, output reg Q);
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
      input	 init,
      input	 A, 
      input	 B, 
      output reg Q);
   always @(*)
     if (init)
       Q <= #1 INITIAL;
     else if (A & B)
       Q <= #1 1;
     else if (!A & !B)
       Q <= #1 0;
endmodule

module sky130_fd_sc_hd__maj3_1 (
    output reg X,
    input  A,
    input  B,
    input  C
);
   always @(*) X = A & B | C & (A | B);
endmodule
