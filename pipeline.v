/*
 * Simple Null-Convention Logic (NCL) example
 *
 * We a simple ring of a 4-valued NCL variable
 */
`default_nettype none
module tb;
   reg init = 0;
   wire [3:0] d;
   wire	      dk;
   
   pipeline pipeline_1(init, d, dk);


   initial begin
      $dumpfile("pipeline.vcd");
      $dumpvars(0, pipeline_1);



      #10 init = 1;
      #100 init = 0;
      #1000 $finish;
   end
endmodule

module pipeline(input  wire       init,
		output wire [3:0] d,
		output wire       dk);

   // Each stage consists of registration, computation, and completion detection

   wire [3:0]		     a, b, c, e;
   wire			     ak, bk, ck, ek;

   wire [3:0]		     d_rot = {d[2:0],d[3]};

   stage st0(init, e | init, bk, a, ak);
   stage st1(init, a,        ck, b, bk);
   stage st2(init, b,        dk, c, ck);
   stage st3(init, c,        ek, d, dk);
   stage st4(init, d_rot,    ak, e, ek);

   reg	      aa = 0;
   reg	      bb = 0;
   wire	      qq;

   always #8 {aa,bb} = {bb,!aa};
   th22 th22_(.Q(qq), .A(aa), .B(bb));
endmodule

module stage(input        init,
	     input  [3:0] a,
	     input	  a_acki,

	     output reg [3:0] b,
	     output reg	  b_acko);

   // registration
   wire			  a_acki_init;
   wire [3:0]		  ar;
   genvar		  i;
   for (i = 0; i < 4; i = i + 1)
     th22 th22_r(.A(a[i] & !init), .B(a_acki & !init), .Q(ar[i]));

   // "computation", we are just rotating the value
   //always @(*) b = #1 {ar[2:0],ar[3]};
   always @(*) b = #10 ar;

   // completion
   always @(*) b_acko = #20 !(|b);
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
