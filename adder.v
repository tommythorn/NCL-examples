/*
 * Simple Null-Convention Logic (NCL) example
 *
 * We a simple ring of a 4-valued NCL variable
 */
`default_nettype none
module tb;
   reg init = 0;
   wire [3:0] d;
   wire [3:0] dn;
   wire	      dk;
   
   pipeline pipeline_1(init, d, dn, dk);


   initial begin
      $dumpfile("pipeline.vcd");
      $dumpvars(0, pipeline_1);



      #10 init = 1;
      #21 init = 0;
      #1000 $finish;
   end
endmodule

module pipeline(input  wire       init,
		output wire [3:0] d,
		output wire [3:0] dn,
		output wire       dk);

   // Each stage consists of registration, computation, and completion detection

   wire [3:0]		     a, b, c, e;
   wire [3:0]		     an, bn, cn, en;
   wire			     ak, bk, ck, ek;

   wire [3:0]		     s, sn;
   wire [3:0]		     d_rot  = init ? 4'h1 : s;
   wire [3:0]		     dn_rot = init ? 4'he : sn;

   adder #(4) adder_i(d, dn, 4'd1, 4'd14, s, sn);

   stage st0(init, e, en,           dk, a, an, ak);
   stage st3(init, a, an,           ek, d, dn, dk);
   stage st4(init, d_rot, dn_rot,   ak, e, en, ek);
endmodule

module stage(input             init,

	     input [3:0]       a,
	     input [3:0]       an,
	     input	       a_acki,

	     output wire [3:0] b,
	     output wire [3:0] bn,
	     output reg        b_acko);

   wire			       error = (a & an) != 0;

   // registration
   wire			  a_acki_init;
   wire [3:0]		  ar;
   wire [3:0]		  anr;
   genvar		  i;
   for (i = 0; i < 4; i = i + 1) begin
     th22 th22_r1(.A(a[i] & !init), .B(a_acki & !init), .Q(ar[i]));
     th22 th22_r2(.A(an[i] & !init), .B(a_acki & !init), .Q(anr[i]));
   end

   // "computation", we are just rotating the value
   //always @(*) b = #1 {ar[2:0],ar[3]};
   assign b = ar;
   assign bn = anr;

   // completion
   wire [3:0] b_complete = b | bn;
   wire [3:0] b_error = b & bn;
   wire [1:0] bb_complete;
   wire	      bbb_complete;
   th22 th22_c0(.A(b_complete[0]), .B(b_complete[1]), .Q(bb_complete[0]));
   th22 th22_c1(.A(b_complete[2]), .B(b_complete[3]), .Q(bb_complete[1]));
   th22 th22_c2(.A(bb_complete[0]), .B(bb_complete[1]), .Q(bbb_complete));
   always @(*) b_acko = !bbb_complete;
endmodule

module adder(a, an, b, bn, r, rn);
   parameter n = 32;
   input wire [n-1:0] a;
   input wire [n-1:0] an;
   input wire [n-1:0] b;
   input wire [n-1:0] bn;
   
   output wire [n-1:0] r;
   output wire [n-1:0] rn;

   wire [n-1:0]	       c;
   wire [n-1:0]	       cn;

   add1 add1_0(a[0], an[0], b[0], bn[0], 1'b0, 1'b1, r[0], rn[0], c[0], cn[0]);
   genvar	       i;
   for (i = 1; i < n; i = i + 1)
     add1 add1_i(a[i], an[i], b[i], bn[i], c[i-1], cn[i-1], r[i], rn[i], c[i], cn[i]);
endmodule

module add1(input wire  a,
	    input wire	an,
	    input wire	b,
	    input wire	bn,
	    input wire	c,
	    input wire	cn,

	    output wire	r,
	    output wire	rn,
	    output wire	co,
	    output wire	con);

/*
   wire a_and_bn; th22 th22_1(a, bn, a_and_bn);
   wire an_and_b; th22 th22_2(an, b, an_and_b);
   wire a_and_b;  th22 th22_3(a, b, a_and_b);
*/   

   // XXX This is broken.  We can't use & but have to use th22 for those
   assign r = a & b & cn | an & b & cn | an & bn & c | a & b & c;
   assign rn = an & b & c | a & bn & c | a & b & cn | an & bn & cn;

   assign co = a & b & (cn|c) | (a|an) & b & c | a & (b|bn) & c;
   assign con = an & bn & (cn|c) | (a|an) & bn & cn | an & (b|bn) & cn;
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
