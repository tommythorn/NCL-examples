// 20230817-19
`default_nettype none
module top(input clk_25mhz,
	   input [6:0] btn, // btn[0] is normally high, the rest normally low
           output wire [7:0] led,
           output wifi_gpio0,
	   output [27:0] gp,
	   output [27:0] gn);

   parameter N = 4;  // Must be >= 3  (3: 456 MHz, 4: 544, 5: 656 MHz, 6: 512)

   // Tie GPIO0, keep board from rebooting
   assign wifi_gpio0 = 1;

   // "User Interface"
   // btn0 is init
   // btn1 is go
   // btn2 is step -- advances once per edge
   //
   // The buttons are in priority order and is ignored if a higher
   // priority button is activated
   //
   // The way we "step" the NCL is to only enable one stage to report
   // completion (hmm, this might not work)

   // NCL "reset"
   reg         init = 0;
   reg	       go   = 0;
   reg	       step = 0;
   reg [N-1:0] enable = ~0;
   reg	       old_step = 0;

   reg [27:0]  clock_divider = 0;
   

   always @(posedge clk_25mhz) begin
      init     <= !btn[0];
      go      <= btn[1];
      step     <= btn[2];

      clock_divider <= clock_divider - 1;
      if (clock_divider[27]) begin
	 clock_divider <= 'd 1_250_000-2;
	 old_step <= step;
	 
	 if (go)
	   enable <= ~0;
	 else begin
	    if (step & !old_step) begin
	       // Step /
	       if (&enable)
		 enable <= 1;
	       else 
		 enable <= {enable[N-2:0],enable[N-1]};
	    end
	 end
      end
   end	

   // N-stage ring of N-1 TH22NI and one TH22D
   // The lone th22di feeds q0, and the rest q
   // The actual performance is extremely sensitive to placement/routing so
   // results vary widely, but as a rule, best results are with N=4 or N=5.
   wire   [N-2:0] d, q, ack;
   wire           d0, q0, ack0;

   assign d0 = q[N-2];
   assign d = {q[N-3:0],q0};      // d[i] = q[i-1 modulo N]

  
   assign ack0 = enable[0] & q[0];
   assign ack = enable[N-1:1] & {q0,q[N-2:1]};    // ack[i] = q[i+1 modulo N]

   (* keep *) TH22DI th22_x         (.Z(q0),.C(init), .A(d0), .B(ack0));
   (* keep *) TH22NI th22_0 [N-2:0] (.Z(q), .C(init), .A(d),  .B(ack));


   // To measure the performance we have to divide the async clock
   // down as it is much too fast for the IO
   reg async_clock_div2; always @(posedge q[0]) async_clock_div2 <= !async_clock_div2;
   reg async_clock_div4; always @(posedge async_clock_div2) async_clock_div4 <= !async_clock_div4;
   reg async_clock_div8; always @(posedge async_clock_div4) async_clock_div8 <= !async_clock_div8;
   reg async_clock_div16; always @(posedge async_clock_div8) async_clock_div16 <= !async_clock_div16;

   assign gp[0] = q[0];
   assign gp[1] = async_clock_div2;
   assign gp[2] = async_clock_div4;
   assign gp[3] = async_clock_div8;
   assign gp[4] = async_clock_div16;
   assign gp[5] = async_clock_div16;
   assign gp[6] = async_clock_div16;

   reg [25:0] async_counter = 0;
   reg [7:0]  async_led_r;
   assign led = async_led_r;
   always @(posedge async_clock_div16) begin
      async_counter <= async_counter + 1;
   end

   always @(posedge clk_25mhz)
      async_led_r <= go ? async_counter[25:25-7] : {ack,ack0,q,q0}; // At 600 MHz, this should roll over every 1.79 s
endmodule
