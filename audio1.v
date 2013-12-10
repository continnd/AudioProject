module AudioRecorder(
  // Clock Input (50 MHz)
  input CLOCK_50, // 50 MHz
  input CLOCK_27, // 27 MHz
  //  Push Buttons
  input  [3:0]  KEY,
  //  DPDT Switches 
  input  [17:1]  SW,
  //  7-SEG Displays
  // TV Decoder
  output TD_RESET, // TV Decoder Reset
  // I2C
  inout  I2C_SDAT, // I2C Data
  output I2C_SCLK, // I2C Clock
  // Audio CODEC
  output/*inout*/ AUD_ADCLRCK, // Audio CODEC ADC LR Clock
  input	 AUD_ADCDAT,  // Audio CODEC ADC Data
  output /*inout*/  AUD_DACLRCK, // Audio CODEC DAC LR Clock
  output AUD_DACDAT,  // Audio CODEC DAC Data
  inout	 AUD_BCLK,    // Audio CODEC Bit-Stream Clock
  output AUD_XCK,     // Audio CODEC Chip Clock
  inout [15:0]SRAM_DQ,
  output reg [17:0]SRAM_ADDR,
  output SRAM_WE_N,
  output SRAM_UB_N,
  output SRAM_LB_N,
  output SRAM_CE_N,
  output SRAM_OE_N,
  input rst,
  output [8:0]LEDG
);

reg[15:0] mem_in;
wire [6:0] myclock;

assign SRAM_DQ = 16'hzzzz;
assign SRAM_UB_N = 1'b0;
assign SRAM_LB_N = 1'b0;
assign SRAM_CE_N = 1'b0;
assign SRAM_OE_N = 1'b0;

// reset delay gives some time for peripherals to initialize
wire DLY_RST;
Reset_Delay r0(	.iCLK(CLOCK_50),.oRESET(DLY_RST) );

assign	TD_RESET = 1'b1;  // Enable 27 MHz

VGA_Audio_PLL 	p1 (	
	.areset(~DLY_RST),
	.inclk0(CLOCK_27),
	.c0(VGA_CTRL_CLK),
	.c1(AUD_CTRL_CLK),
	.c2(VGA_CLK)
);

I2C_AV_Config u3(	
//	Host Side
  .iCLK(CLOCK_50),
  .iRST_N(KEY[0]),
//	I2C Side
  .I2C_SCLK(I2C_SCLK),
  .I2C_SDAT(I2C_SDAT)	
);

assign	AUD_ADCLRCK	=	AUD_DACLRCK;
assign	AUD_XCK		=	AUD_CTRL_CLK;

audio_clock u4(	
//	Audio Side
   .oAUD_BCK(AUD_BCLK),
   .oAUD_LRCK(AUD_DACLRCK),
//	Control Signals
  .iCLK_18_4(AUD_CTRL_CLK),
   .iRST_N(DLY_RST)	
);

reg [3:0] S;
reg [3:0] NS;

reg [17:0] trck1lngth;
reg [17:0] trck2lngth;
reg firsttime;
reg secondtime;

reg [17:0]nextAddress1;
reg [17:0]nextAddress2;

reg mixcontrol;
reg writecontrol;
reg [16:0] sampletemp;
reg write;

reg overwritetrack;

parameter INIT = 4'd10,
	SETLENGTH1 = 4'd11,
	SETLENGTH2 = 4'd12,
	BLANK = 4'd0, 
	MIXINIT = 4'd1, 
	GETSAMPLE = 4'd2, 
	SWITCHADDRESS = 4'd3,
       	ADDSAMPLES=4'd4,
	MIXSAMPLE1 = 4'd5, 
	SAVESAMPLE = 4'd6, 
	COUNTUP = 4'd7,
	SUBTRACTSAMPLES = 4'd8,
	MIXSAMPLE2 = 4'd9;

wire [15:0] audio_inL, audio_inR;
wire [15:0] audio_outL,audio_outR;

always @(posedge AUD_DACLRCK)
begin
	if(!rst)
		S<=BLANK;
	else if(!SW[1])
		S<=INIT;
	else
		S<=NS;
	
	if(S==INIT)
	begin
		trck1lngth<=18'd0;
		trck2lngth<=18'd0;
		firsttime<=1'b1;
	end
	if(S==SETLENGTH1)
	begin
		if(!KEY[1] && firsttime)
		begin
			trck1lngth<=trck1lngth+18'd24000;
			firsttime<=1'b0;
		end
		if(!KEY[0] && firsttime)
		begin
			trck1lngth<=trck1lngth-18'd24000;
			firsttime<=1'b0;
		end
		if(KEY[0] && KEY[1])
			firsttime<=1'b1;
		secondtime = 1'b0;
	end
	if(S==SETLENGTH2)
	begin
		if(!KEY[1])
		begin
			trck2lngth<=trck2lngth+18'd24000;
			firsttime<=1'b0;
		end
		if(!KEY[0])
		begin
			trck2lngth<=trck2lngth-18'd24000;
			firsttime<=1'b0;
		end
		if(KEY[0] && KEY[1])
			firsttime<=1'b1;
		if(KEY[2])
			secondtime = 1'b1;
		SEL_Addr1<=18'd0;
		SEL_Addr2<=trck1lngth;
	end
	if(S==BLANK)
	begin
		write <= SW[17];
		if(!rst)
		begin
			SEL_Addr1 <= 18'd0;
			SEL_Addr2 <= trck1lngth;
		end
		else
		begin
			SEL_Addr1 <= nextAddress1;
			SEL_Addr2 <= nextAddress2;
		end

		if(!SW[17])
		begin
			audioR <= audio_inR;
			mem_in <= audio_inR;
		end
		else
			audioR <= SRAM_DQ;
	end
	else
		audioR<=16'd0;
	if(S== MIXINIT) begin
			SEL_Addr1 <= 18'd0;
			SEL_Addr2 <= trck1lngth; //18'd128000;
			mixcontrol <= 1'b1;
			write <= 1'b1;
		end
	if(S==	GETSAMPLE) begin
		sampletemp <= SRAM_DQ;
	end
	if(S==SWITCHADDRESS) mixcontrol <= 1'b0;
	if(S==ADDSAMPLES) begin
		sampletemp <= SRAM_DQ + (sampletemp - 17'd32767);
	end
	if(S==SUBTRACTSAMPLES) begin
		sampletemp <= SRAM_DQ - (17'd32767-sampletemp);
	end
	if(S==MIXSAMPLE1) begin
	       sampletemp <= sampletemp - (sampletemp-17'd32767)/17'd2;
	       write <= 1'b0;
	       mixcontrol <= overwritetrack;
       	end
	if(S==MIXSAMPLE2) begin
		sampletemp <= sampletemp + (17'd32767 - sampletemp)/17'd2;
		write <= 1'b0;
		mixcontrol <= overwritetrack;
	end
	if(S==SAVESAMPLE) mem_in<=sampletemp;
	if(S==COUNTUP) begin
		SEL_Addr1<=nextAddress1;
		SEL_Addr2<=nextAddress2;
		write<= 1'b1;
		mixcontrol <= 1'b1;
		end
	//endcase
end
always @(negedge AUD_DACLRCK)
begin
	if(!SW[17])
		audioL <= audio_inL;
	else if(S==BLANK)
		audioL <= SRAM_DQ;
	else
		audioL <= 16'd0;
end

reg [15:0]audioL;
reg [15:0]audioR;
reg[17:0] SEL_Addr1;
reg[17:0] SEL_Addr2;

always @(*)
begin
	LEDG[8] = (~KEY[3])|(~KEY[2])|(~KEY[1])|(~KEY[0]);
	if(SEL_Addr1!=trck1lngth)
		nextAddress1 = SEL_Addr1 + 18'd1;
	else if(SEL_Addr1 == trck1lngth && SW[12])
		nextAddress1 = 18'd0;
	else
		nextAddress1 = SEL_Addr1;

	if(SEL_Addr2!=trck2lngth + trck1lngth)
		nextAddress2 <= SEL_Addr2 + 18'd1;
	else if(SEL_Addr2==trck2lngth + trck1lngth && SW[12])
		nextAddress2 <= trck1lngth;
	else
		nextAddress2 <= SEL_Addr2;

	if(trck1lngth>trck2lngth)
		overwritetrack = 1'b1;
	else
		overwritetrack = 1'b0;

	if(S==BLANK)
	begin
	
		if(SW[15])
			SRAM_ADDR=SEL_Addr1;
		else if(SW[14])
			SRAM_ADDR=SEL_Addr2;
		else
			SRAM_ADDR=18'd0; 
	//	write = SW[17];
	end
	else
	begin
		if(mixcontrol)
			SRAM_ADDR=SEL_Addr1;
		else
			SRAM_ADDR=SEL_Addr2;
	//	write = writecontrol;
	end
	case(S)
		INIT: NS = SETLENGTH1;
		SETLENGTH1: begin
			if(!KEY[2])
				NS=SETLENGTH2;
			else
				NS=SETLENGTH1;
			
		end
		SETLENGTH2: begin
			if(!KEY[2] && secondtime)
				NS=BLANK;
			else
				NS=SETLENGTH2;
			
		end
		BLANK: begin
			if(!KEY[3])
				NS=MIXINIT;
			else
				NS=BLANK;
		end
		MIXINIT: NS=GETSAMPLE;
		GETSAMPLE: NS=SWITCHADDRESS;
		SWITCHADDRESS: begin
			if(sampletemp>17'd32767) 
				NS=ADDSAMPLES;
			else 
				NS=SUBTRACTSAMPLES;
		end
		SUBTRACTSAMPLES: begin
		       if(sampletemp>17'd32767) 
				NS=MIXSAMPLE1;
			else 
				NS=MIXSAMPLE2;
		end
		ADDSAMPLES: begin
			if(sampletemp>17'd32767) 
				NS=MIXSAMPLE1;
			else 
				NS=MIXSAMPLE2;
		end
		MIXSAMPLE1: NS = SAVESAMPLE;
		MIXSAMPLE2: NS = SAVESAMPLE;
		SAVESAMPLE: NS = COUNTUP;
		COUNTUP: begin
			if(trck1lngth>trck2lngth)
			begin
				if(nextAddress1 == trck1lngth - 1'b1)
					NS=BLANK;
				else
					NS=GETSAMPLE;
			end
			else
			begin
				if(nextAddress2 == trck1lngth + trck2lngth - 1'b1)
					NS=BLANK;
				else
					NS=GETSAMPLE;
			end
		end
	endcase
end
assign SRAM_DQ = write ? 16'hzzzz : mem_in;
assign SRAM_WE_N = write;

	
assign audio_outL = audioL;
assign audio_outR = audioR;


audio_converter u5(
	// Audio side
	.AUD_BCK(AUD_BCLK),       // Audio bit clock
	.AUD_LRCK(AUD_DACLRCK), // left-right clock
	.AUD_ADCDAT(AUD_ADCDAT),
	.AUD_DATA(AUD_DACDAT),
	// Controller side
	.iRST_N(DLY_RST),  // reset
	.AUD_outL(audio_outL),
	.AUD_outR(audio_outR),
	.AUD_inL(audio_inL),
	.AUD_inR(audio_inR)
);

endmodule
