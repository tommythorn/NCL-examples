/*
 * Simple Null-Convention Logic (NCL) examples
 * 20230816
 * A simple 6 ring of a n-valued NCL variable, with 2 tokens!
 *
 * WAIT ...(Even here a single token is much faster.  I assume it's because
 * holes (NULL) travel faster than data.)
 *
 */
`default_nettype none
module tb;
   parameter W = 16;
   reg init = 0;
   wire [W-1:0] d;
   wire	      dk;
   
   pipeline #(W) pipeline_1(init, d, dk);


   initial begin
      $dumpfile("pipeline.vcd");
      $dumpvars(0, pipeline_1);



      #1 init = 1;
      #59 init = 0;
      #10000 $finish;
   end
endmodule

module pipeline#(parameter W = 3)
	       (input  wire       init,
		output wire [W-1:0] d,
		output wire       dk);

   // Each stage consists of registration, computation, and completion
   // detection
   wire [W-1:0]		     a, b, c, e, f;
   wire			     ak, bk, ck, ek, fk;

   wire [W-1:0]		     d_rot = {d[W-2:0],d[W-1]};

   // Note, "9" means the stage will be NULL initialized
   // The "1" get's initialized to DATA(1 << 1) = DATA(2)
   // and the "3" get's initialized to DATA(1 << 3) = DATA(8)
   stage #(W,0) st0(init, f,        bk,   a, ak);
   stage #(W,99) st1(init, a,        ck,   b, bk);
   stage #(W,99) st2(init, b,        dk,   c, ck);
   stage #(W,99) st3(init, c,        ek,   d, dk);
   stage #(W,4) st4(init, d_rot,    fk,   e, ek);
   stage #(W,99) st5(init, e,        ak,   f, fk);
endmodule

module stage#(parameter W = 3,
	      parameter INIT = 99)
            (input        init,
	     input  [W-1:0] a,
	     input	  a_acki,

	     output reg [W-1:0] b,
	     output reg	  b_acko);

   // registration
   wire [W-1:0]		  ar;
   genvar		  i;
   for (i = 0; i < W; i = i + 1)
     th22i #(i == INIT) 
          th22_r(.init(init), .A(a[i]), .B(a_acki), .Q(ar[i]));

   // "computation"
   always @(*) b <= #2 ar;

   // completion
   always @(*) b_acko <= #0 !(|b);
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
