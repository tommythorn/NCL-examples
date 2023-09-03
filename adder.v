/*
 * 20230820, 20230823
 * Simple Null-Convention Logic (NCL) example
 *
 * We make a simple ring of a 4-valued NCL variable
 */
`default_nettype none
module tb;
   reg init = 0;
   wire [3:0] d0;
   wire [3:0] d1;
   wire	      dk;

   pipeline pipeline_1(init, d0, d1, dk);

   always @(posedge dk)
     $display("got %d", d1);

   initial begin
      $dumpfile("pipeline.vcd");
      $dumpvars(0, pipeline_1);

      #10 init = 1;
      #21 init = 0;
      #1000 $finish;
   end
endmodule

module pipeline(input  wire       init,
		output wire [3:0] d0,
		output wire [3:0] d1,
		output wire       dk);

   // Each stage consists of registration, computation, and completion detection

   wire [3:0]		     a0, b0, c0, e0;
   wire [3:0]		     a1, b1, c1, e1;
   wire			     ak, bk, ck, ek;

   wire [3:0]		     s0, s1;

   adder #(4) adder_i(d0, d1, 4'd14, 4'd1, s0, s1);
   stage st0(init, e0, e1 | init, dk, a0, a1, ak);
   stage st3(init, a0, a1,        ek, d0, d1, dk);
   stage st4(init, s0, s1,        ak, e0, e1, ek);
endmodule

module stage(input             init,

	     input [3:0]       a0,
	     input [3:0]       a1,
	     output            a_comp,

	     output wire [3:0] b0,
	     output wire [3:0] b1,
	     input	       b_comp);

   // registration
   wire			  a_acki_init;
   genvar		  i;
   for (i = 0; i < 4; i = i + 1) begin
     th22ni th22_r0(.A(a0[i]), .COMP(k), .INIT(init), .Q(b0[i]));
     th22ni th22_r1(.A(a1[i]), .COMP(k), .INIT(init), .Q(b1[i]));
   end

   // completion
   wire [3:0] b_comp1 = b0 | b1;
   wire [1:0] b_comp2;
   th22 th22_c0(.A(b_comp1[0]), .B(b_comp1[1]), .Q(b_comp2[0]));
   th22 th22_c1(.A(b_comp1[2]), .B(b_comp1[3]), .Q(b_comp2[1]));
   th22 th22_c2(.A(b_comp2[0]), .B(b_comp2[1]), .Q(b_comp));
endmodule

module adder #(parameter n = 32)
   (input wire [n-1:0] a0,
    input wire [n-1:0] a1,
    input wire [n-1:0] b0,
    input wire [n-1:0] b1,
    output wire [n-1:0]	s0,
    output wire [n-1:0]	s1);

   wire [n-1:0]	       c0, c1;

   add1 add1_0(a0[0], a1[0], b0[0], b1[0], 1'b1, 1'b0, s0[0], s1[0], c0[0], c1[0]);
   genvar i;
   for (i = 1; i < n; i = i + 1)
     add1 add1_i(a0[i], a1[i], b0[i], b1[i], c0[i-1], c1[i-1], s0[i], s1[i], c0[i], c1[i]);
endmodule

// Dual-rail full-adder
module add1(input wire	a0,
	    input wire  a1,
	    input wire	b0,
	    input wire	b1,
	    input wire	ci0,
	    input wire	ci1,

	    // Sum and Carry-out
	    output wire	s0,
	    output wire	s1,
	    output wire	co0,
	    output wire	co1);

   // a b ci | co s
   // 0 0 0  | 0  0
   // 0 0 1  | 0  1
   // 0 1 0  | 0  1
   // 0 1 1  | 1  0
   // 1 0 0  | 0  1
   // 1 0 1  | 1  0
   // 1 1 0  | 1  0
   // 1 1 1  | 1  1

   wire i000, i001, i010, i011, i100, i101, i110, i111;
   th33 th33_0(.Q(i000), .A(a0), .B(b0), .C(ci0));
   th33 th33_1(.Q(i001), .A(a1), .B(b0), .C(ci0));
   th33 th33_2(.Q(i010), .A(a0), .B(b1), .C(ci0));
   th33 th33_3(.Q(i011), .A(a1), .B(b1), .C(ci0));
   th33 th33_4(.Q(i100), .A(a0), .B(b0), .C(ci1));
   th33 th33_5(.Q(i101), .A(a1), .B(b0), .C(ci1));
   th33 th33_6(.Q(i110), .A(a0), .B(b1), .C(ci1));
   th33 th33_7(.Q(i111), .A(a1), .B(b1), .C(ci1));

   assign s0  = i110 | i101 | i011 | i000;
   assign s1  = i001 | i010 | i100 | i111;
   assign co0 = i100 | i010 | i001 | i000;
   assign co1 = i011 | i101 | i110 | i111;
endmodule


// Threshold 1-of-2 gate, also known as "or"
module th12(input A, input B, output reg Q);
   always @(*) Q = #2 A | B;
endmodule

// Threshold 2-of-2 gate, also known as Muller's C-element
module th22(input A, input B, output reg Q);
   // We can implement this with a majority gate with feedback
   //sky130_fd_sc_hd__maj3_1 maj(.X(Q), .A(A), .B(B), .C(Q));
   always @(*) if (A == B) Q <= #1 A;
endmodule

// NULL initialized Threshold 2-of-2 gate with completion (inverted ack)
module th22ni(input A, input COMP, input INIT, output reg Q);
   always @(*) if (INIT) Q <= 0; else if (A != COMP) Q <= #1 A;
endmodule

// DATA initialized Threshold 2-of-2 gate with completion (inverted ack)
module th22di(input A, input COMP, input INIT, output reg Q);
   always @(*) if (INIT) Q <= 1; else if (A != COMP) Q <= #1 A;
endmodule

// Threshold 3-of-3 gate
module th33(input A, input B, input C, output reg Q);
   always @(*) if (A == B && B == C) Q <= #1 A;
endmodule

module sky130_fd_sc_hd__maj3_1 (
    output reg X,
    input  A,
    input  B,
    input  C
);
   always @(*) X = A & B | C & (A | B);
endmodule















// 2NCL mapping for booleans
module ncl_or(input [1:0] a, input [1:0] b, output [1:0] q);
   // N X -> hold
   // X N -> hold
   // D(0) D(0) -> D(0)
   // D(0) D(1) -> D(1)
   // D(1) D(0) -> D(1)
   // D(1) D(1) -> D(1)

   /* old formulation
   // This is Fants mapping
   th22 th22_1(.Q(q[0]), .A(a[0]), .B(b[0]));  // When both are 0, output is 0
   th34w32 th34w32_1(.Q(q[1]),                       // a[1]*2 + b[1]*2 + a[0] + b[0] >= 3
		     .A(a[1]), // W2
		     .B(b[1]), // W2
		     .C(a[0]),
		     .D(b[0]));
   */

   // Modern version, much more intuitive
   wire [3:0] t;
   th22 th22_0(.Q(t[0]), .A(a[0]), .B(b[0]));
   th22 th22_1(.Q(t[1]), .A(a[0]), .B(b[1]));
   th22 th22_2(.Q(t[2]), .A(a[1]), .B(b[0]));
   th22 th22_3(.Q(t[3]), .A(a[1]), .B(b[1]));
   assign q = {|t[3:0], t[0]};
endmodule

module ncl_xor(input [1:0] a, input [1:0] b, output [1:0] q);
   wire [3:0] t;
   th22 th22_0(.Q(t[0]), .A(a[0]), .B(b[0]));
   th22 th22_1(.Q(t[1]), .A(a[0]), .B(b[1]));
   th22 th22_2(.Q(t[2]), .A(a[1]), .B(b[0]));
   th22 th22_3(.Q(t[3]), .A(a[1]), .B(b[1]));
   assign q = {t[2] | t[1], t[3] | t[0]};
endmodule

module sky130_fd_sc_hd__inv_1 (
    output reg Y,
    input  A
);
   always @(*) Y = #1 !A;
endmodule
