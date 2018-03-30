--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: WIB_FEMB_COMM_TOP_EMU.VHD           
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 08/08/2016
--////  Description:  WIB_FEMB_COMM
--////					
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2016 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;


--  Entity Declaration



ENTITY WIB_FEMB_COMM_TOP_EMU IS
	PORT
	(
		RESET   	   			: IN 	STD_LOGIC;					-- SYSTEM RESET
		SYS_CLK	   			: IN 	STD_LOGIC;					-- SYSTEM CLOCK
				
				
		FEMB_wr_strb 			: IN STD_LOGIC;								-- FEMB REGISTER WRITE
		FEMB_rd_strb 			: IN STD_LOGIC;								-- FEMB REGISTER READ
		FEMB_address 			: IN  STD_LOGIC_VECTOR(15 downto 0);	-- REGISTER ADDRESS
		FEMB_BRD					: IN  STD_LOGIC_VECTOR(3 downto 0);    --  BOARD CHANNEL NUMBER
		FEMB_DATA_TO_FEMB		: IN  STD_LOGIC_VECTOR(31 downto 0);	-- DATA TO THE FEMB
		FEMB_DATA_RDY			: OUT  STD_LOGIC;								-- DATA READY FROM FEMB READBACK STROBE
		FEMB_DATA_FRM_FEMB 	: OUT  STD_LOGIC_VECTOR(31 downto 0);	-- FROM THE FEMB
		
		
		FEMB_SCL_BRD0			:	OUT	STD_LOGIC;				--	LVDS ,	FEMB DIFF I2C  CLOCK
		FEMB_SDA_BRD0_P		:	INOUT STD_LOGIC;				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA
		FEMB_SDA_BRD0_N		:	INOUT STD_LOGIC				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA

	);
	
END WIB_FEMB_COMM_TOP_EMU;


ARCHITECTURE behavior OF WIB_FEMB_COMM_TOP_EMU IS

		
SIGNAL		FEMB_wr_strb_0      		: STD_LOGIC;		
SIGNAL		FEMB_rd_strb_0      		: STD_LOGIC;		
SIGNAL		FEMB_DATA_RDY_0      	: STD_LOGIC;		
SIGNAL		FEMB_DATA_FRM_FEMB_0		: STD_LOGIC_VECTOR(31 downto 0);	


begin
	

	FEMB_wr_strb_0		<= FEMB_wr_strb WHEN (FEMB_BRD = X"0") ELSE '0';
	FEMB_rd_strb_0		<= FEMB_rd_strb WHEN (FEMB_BRD = X"0") ELSE '0';

	
	FEMB_DATA_FRM_FEMB	<= FEMB_DATA_FRM_FEMB_0 WHEN (FEMB_BRD = X"0") ELSE 
									X"00000000";

	FEMB_DATA_RDY			<= FEMB_DATA_RDY_0 WHEN (FEMB_BRD = X"0") ELSE 
									'0';
									
									
									
WIB_FEMB_COMM_INST1 : ENTITY WORK.WIB_FEMB_COMM
	PORT MAP
	(
		RESET   	   		=> RESET,
		SYS_CLK	   		=> SYS_CLK,
		
		FEMB_SCL				=> FEMB_SCL_BRD0,
		FEMB_SDA_P			=> FEMB_SDA_BRD0_P,
		FEMB_SDA_N			=>	FEMB_SDA_BRD0_N,	
		
		FEMB_wr_strb 		 => FEMB_wr_strb_0,
		FEMB_rd_strb 		 => FEMB_rd_strb_0, 
		FEMB_address 	 	 => FEMB_address,
		FEMB_DATA_TO_FEMB  => FEMB_DATA_TO_FEMB,
		FEMB_DATA_RDY		 => FEMB_DATA_RDY_0,
		FEMB_DATA_FRM_FEMB => FEMB_DATA_FRM_FEMB_0
	);
	
		
	
END behavior;
