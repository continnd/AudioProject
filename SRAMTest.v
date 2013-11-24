module SRAMTest(
     input [17:0]SW,
     inout tri [15:0] SRAM_DQ,   // SRAM Data bus 16 Bits
	  output [17:0] SRAM_ADDR, // SRAM Address bus 18 Bits
     output SRAM_UB_N,        // SRAM High-byte Data Mask
     output SRAM_LB_N,        // SRAM Low-byte Data Mask 
     output reg SRAM_WE_N,    // SRAM Write Enable
     output SRAM_CE_N,        // SRAM Chip Enable
     output SRAM_OE_N,        // SRAM Output Enable
     output [17:0]  LEDR,  //  LED Red[17:0]
     input CLOCK_50,
     input [3:0]KEY
     );
        
reg [7:0]mem_addr;
reg write;
reg [7:0]mem_in;
reg [15:0]mem_out;
assign SRAM_DQ = 16'hzzzz;
        
assign SRAM_UB_N = 1'b0;        // SRAM High-byte Data Mask
assign SRAM_LB_N = 1'b0;        // SRAM Low-byte Data Mask 
assign SRAM_CE_N = 1'b0;        // SRAM Chip Enable
assign SRAM_OE_N = 1'b0;        // SRAM Output Enable
     
     always @(posedge CLOCK_50)
     begin
          mem_in <= SW[7:0];
          SRAM_WE_N <= KEY[3];
			 mem_out <= SRAM_DQ;
			 mem_addr <= SW[17:10];
     end
assign SRAM_DQ = (KEY[3] ? 16'hzzzz : {8'd0,mem_in});
assign LEDR = {2'd0,mem_out};
assign SRAM_ADDR = {10'd0,mem_addr};
endmodule