// 20230817-19
`default_nettype none
module top(input clk_25mhz,
	   input [6:0] btn, // btn[0] is normally high, the rest normally low
           output wire [7:0] led,
           output wifi_gpio0,
	   output [27:0] gp,
	   output [27:0] gn);

   // Tie GPIO0, keep board from rebooting
   assign wifi_gpio0 = 1;

   // NCL "reset"
   wire           init = !btn[0];

   // N-stage ring of N-1 th22ni and one th22d
   // The lone th22di feeds q0, and the rest q
   // The actual performance is extremely sensitive to placement/routing so
   // results vary widely, but as a rule, best results are with N=4 or N=5.
   parameter N = 4;  // Must be >= 3  (3: 456 MHz, 4: 544, 5: 656 MHz, 6: 512)
   wire   [N-2:0] d, q, ack;
   wire           d0, q0, ack0;

   assign d0 = q[N-2];
   assign d = {q[N-3:0],q0};      // d[i] = q[i-1 modulo N]
   assign ack0 = q[0];
   assign ack = {q0,q[N-2:1]};    // ack[i] = q[i+1 modulo N]

   (* keep *) th22di th22_x         (.z(q0),.init(init), .a(d0), .ack(ack0));
   (* keep *) th22ni th22_0 [N-2:0] (.z(q), .init(init), .a(d),  .ack(ack));


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
      async_led_r <= async_counter[25:25-7]; // At 600 MHz, this should roll over every 1.79 s
   end
endmodule
