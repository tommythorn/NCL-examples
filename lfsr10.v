/*
 * 20230816
 * The synchronous LFSR from Chapter 14
 *
 */
`default_nettype none
module tb;
   wire [9:0] lfsr;
   reg	      reset = 1;
   reg	      clock = 1;
   always #5 clock = !clock;
   pipeline pipeline_1(reset, clock, lfsr);

   initial begin
      $dumpfile("pipeline.vcd");
      $dumpvars(0, pipeline_1);
      #11 reset = 0;
      #100000 $finish;
   end
endmodule

module pipeline(input  reset,
		input  clock,
		output reg [9:0] r);

   always @(posedge clock)
     if (reset) begin
	r <= 'hA0;
     end else begin
	// Curious LFSR; it only has 217 unique values
	//
	$display(r);
	r[0] <= r[9] ^ ((r[8] ^ r[7]) ^ (r[1] ^ r[2]));
	r[1] <= r[0];
	r[2] <= r[1];
	r[3] <= r[2];
	r[4] <= r[3];
	r[5] <= r[4];
	r[6] <= r[5];
	r[7] <= r[6];
	r[8] <= r[7] ^ ((r[6] ^ r[5]) ^ (r[3] ^ r[4]));
	r[9] <= r[8];
     end
endmodule
