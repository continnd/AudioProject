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
  input rst
);

reg[15:0] mem_in;
wire [6:0] myclock;
wire RST;
assign RST = KEY[0];

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

reg [2:0] S;
reg [2:0] NS;

reg mixcontrol;
reg writecontrol;
reg [16:0] sampletemp;
reg [17:0] count;
reg write;
reg [17:0]address;

parameter BLANK = 3'd0, 
	MIXINIT = 3'd1, 
	GETSAMPLE = 3'd2, 
	SWITCHADDRESS = 3'd3, 
	MIXSAMPLE = 3'd4, 
	SAVESAMPLE = 3'd5, 
	COUNTUP = 3'd6;

wire [15:0] audio_inL, audio_inR;
wire [15:0] audio_outL,audio_outR;

always @(posedge AUD_DACLRCK)
begin
	if(!rst)
		S<=BLANK;
	else
		S<=NS;
/*	case(S)
		RW: begin */
	       if(!SW[13])
	       begin
			if(!SW[17])
			begin
				audioR <= audio_inR;
				mem_in <= audio_inR;
				if(!rst)
				begin
					SEL_Addr1 <= 18'd0;
					SEL_Addr2 <= 18'd128000;
				end
				else
				begin
					if(SEL_Addr1==18'd127999)
						SEL_Addr1 <= 18'd0;
					else
						SEL_Addr1 <= SEL_Addr1 + 18'd1;
					if(SEL_Addr2==255999)
						SEL_Addr2 <= 18'd128000;
					else
						SEL_Addr2 <= SEL_Addr2 + 18'd1;
				end
			end
			else
			begin
				audioR <= SRAM_DQ;
				if(!rst)
				begin
					SEL_Addr1 <= 18'd0;
					SEL_Addr2 <= 18'd128000;
				end
				else
				begin
					if(SEL_Addr1==18'd127999)
						SEL_Addr1 <= 18'd0;
					else
						SEL_Addr1 <= SEL_Addr1 + 18'd1;
					if(SEL_Addr2==255999)
						SEL_Addr2 <= 18'd128000;
					else
						SEL_Addr2 <= SEL_Addr2 + 18'd1;
				end
			end
		end
	else
	case(S)
		MIXINIT: begin
			SEL_Addr1 <= 1'b0;
			SEL_Addr2 <= 1'b0;
			mixcontrol <= 1'b1;
			writecontrol <= 1'b1;
		end
		GETSAMPLE: begin
			sampletemp <= SRAM_DQ;
		end
		SWITCHADDRESS: mixcontrol <= 1'b0;
		MIXSAMPLE: begin
			sampletemp <= (sampletemp+SRAM_DQ)/2;
			mixcontrol <= 1'b1;
			writecontrol <= 1'b0;
		end
		SAVESAMPLE: mem_in <= sampletemp[15:0];
		COUNTUP: begin
			count <= count + 18'd1;
			writecontrol <= 1'b1;
		end
	endcase
end
always @(negedge AUD_DACLRCK)
begin
	if(!SW[17])
		audioL <= audio_inL;
	else
		audioL <= SRAM_DQ;
end

reg [15:0]audioL;
reg [15:0]audioR;
reg[17:0] SEL_Addr1;
reg[17:0] SEL_Addr2;

always @(*)
begin
	if(!SW[13])
	begin
	
		if(SW[15])
			SRAM_ADDR=SEL_Addr1;
		else if(SW[14])
			SRAM_ADDR=SEL_Addr2;
		else
			SRAM_ADDR=18'd0; 
		write = SW[17];
	end
	else
	begin
		if(mixcontrol)
			address=SEL_Addr1;
		else
			address=SEL_Addr2;
		write = writecontrol;
	end
	case(S)
		BLANK: begin
			if(SW[13])
				NS=MIXINIT;
			else
				NS=BLANK;
		end
		MIXINIT: NS=GETSAMPLE;
		GETSAMPLE: NS=SWITCHADDRESS;
		SWITCHADDRESS: NS=MIXSAMPLE;
		MIXSAMPLE: NS=SAVESAMPLE;
		SAVESAMPLE: NS=COUNTUP;
		COUNTUP: begin
			if(count == 18'd128000)
				NS=BLANK;
			else
				NS=GETSAMPLE;
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
