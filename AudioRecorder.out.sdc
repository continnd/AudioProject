## Generated SDC file "AudioRecorder.out.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition"

## DATE    "Sat Dec 07 16:28:40 2013"

##
## DEVICE  "EP2C35F672C6"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLOCK_27} -period 37.037 -waveform { 0.000 18.518 } [get_ports {CLOCK_27}]
create_clock -name {I2C_AV_Config:u3|mI2C_CTRL_CLK} -period 1.000 -waveform { 0.000 0.500 } [get_registers {I2C_AV_Config:u3|mI2C_CTRL_CLK}]
create_clock -name {CLOCK_50} -period 1.000 -waveform { 0.000 0.500 } [get_ports {CLOCK_50}]
create_clock -name {audio_clock:u4|LRCK_1X} -period 1.000 -waveform { 0.000 0.500 } [get_registers {audio_clock:u4|LRCK_1X}]
create_clock -name {audio_clock:u4|oAUD_BCK} -period 1.000 -waveform { 0.000 0.500 } [get_registers {audio_clock:u4|oAUD_BCK}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {p1|altpll_component|pll|clk[1]} -source [get_pins {p1|altpll_component|pll|inclk[0]}] -duty_cycle 50.000 -multiply_by 2 -divide_by 3 -master_clock {CLOCK_27} [get_pins {p1|altpll_component|pll|clk[1]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

