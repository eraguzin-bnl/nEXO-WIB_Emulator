--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: WIB_EMULATOR_FPGA.VHD            
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 12/03/2015 
--////  Modified 12/05/2016
--////  Description:  TOP LEVEL SBND WIB EMULATOR FPGA FIRMWARE  
--////					 		
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2015 Brookhaven National Laboratory
--////

--/////////////////////////////////////////////////////////////////////

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.SbndPkg.all;

entity WIB_EMULATOR_FPGA is
	port 
	(

	-- FPGA CLOCKS	

	refclk3R				: IN STD_LOGIC;					--	LVDS	128MHz from HSMC ADAPTER
--	refclk2				: IN STD_LOGIC;					--	LVDS	, default 125MHz
--	refclk3				: IN STD_LOGIC;					--	LVDS	, default 125MHz
--	refclk4				: IN STD_LOGIC;					--	LVDS	, default 125MHz	
--	refclk5				: IN STD_LOGIC;					--	LVDS	, default 125MHz
	
	SFP_CLK				: IN STD_LOGIC;					-- LVDS	
	clkin_50_top		: IN STD_LOGIC;					--	2.5V, default 50MHz  clkin_50_top
	SBND_CLK				: IN STD_LOGIC;					--	2.5V, default 16MHz  EXTRA SYSTEM CLOCK

	
		--	HIGH SPEED  GIG-E LINK

	P20_rx 				: IN  STD_LOGIC;					--	1.5-V PCML, GIG-E  RX
	P20_tx	 			: OUT STD_LOGIC;					--	1.5-V PCML, GIG-E  TX
	
	P21_rx 				: IN  STD_LOGIC;					--	1.5-V PCML, GIG-E  RX
	P21_tx	 			: OUT STD_LOGIC;					--	1.5-V PCML, GIG-E  TX
	
	P22_rx 				: IN  STD_LOGIC;					--	1.5-V PCML, GIG-E  RX
	P22_tx	 			: OUT STD_LOGIC;					--	1.5-V PCML, GIG-E  TX
	
	P23_rx 				: IN  STD_LOGIC;					--	1.5-V PCML, GIG-E  RX
	P23_tx	 			: OUT STD_LOGIC;					--	1.5-V PCML, GIG-E  TX
	
		-- TRIGGER
		
	TRIGGER_IN			: IN STD_LOGIC;						--SMA Input, J6
	

		--	HIGH SPEED  FEMB LINK

	FEMB_GXB_RX				: IN 	std_logic_vector(3 downto 0);	--	1.5-V PCML, Cold electronics board reciver
	
		--  WIB-FEMB CMD , CLOCK & CONTROL INTERFACE

		
	SYS_CMD_FPGA_OUT		:	OUT	STD_LOGIC;				--	LVDS ,   FEMB CLOCK		16MHZ
	SBND_CLK_FPGA_OUT		:	OUT	STD_LOGIC;				--	LVDS ,	FEMB COMMAND	PWM SIGNAL	
		
	FEMB_SCL_BRD0			:	OUT	STD_LOGIC;				--	LVDS ,	FEMB DIFF I2C  CLOCK
	FEMB_SDA_BRD0_P		:	INOUT STD_LOGIC;				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA
	FEMB_SDA_BRD0_N		:	INOUT STD_LOGIC;				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA
--	FEMB_SDO_BRD0			:	OUT	STD_LOGIC				--	LVDS ,	FEMB DIFF I2C  CLOCK
	user_pb					:	IN		STD_LOGIC_vector(2 downto 0);			
	user_dipsw				:	IN		STD_LOGIC_vector(3 downto 0);			
	user_led					:	OUT	STD_LOGIC_vector(3 downto 0)
	
	);
end entity;

architecture WIB_EMULATOR_FPGA_ARCH of WIB_EMULATOR_FPGA is


COMPONENT sys_rst
	PORT(
			clk 			: IN STD_LOGIC;
			reset_in 	: IN STD_LOGIC;
			start 		: OUT STD_LOGIC;
			RST_OUT 		: OUT STD_LOGIC
	);
END COMPONENT;


	component WIB_PLL_SYS is
		port (
			refclk   : in  std_logic := 'X'; -- clk
			rst      : in  std_logic := 'X'; -- reset
			outclk_0 : out std_logic;        -- clk
			outclk_1 : out std_logic;        -- clk
			outclk_2 : out std_logic;        -- clk
			outclk_3 : out std_logic ;        -- clk
			outclk_4 : out std_logic         -- clk
		);
	end component WIB_PLL_SYS;


	component SYSTEM_SYNC_PLL is
		port (
			refclk   : in  std_logic := 'X'; -- clk
			rst      : in  std_logic := 'X'; -- reset
			outclk_0 : out std_logic;        -- clk
			outclk_1 : out std_logic;        -- clk
			outclk_2 : out std_logic;        -- clk
			locked   : out std_logic         -- export
		);
	end component SYSTEM_SYNC_PLL;





	
SIGNAL	clk_125Mhz 		:  STD_LOGIC;
SIGNAL	clk_100Mhz 		:  STD_LOGIC;
SIGNAL	clk_50Mhz		:  STD_LOGIC;
SIGNAL	clk_40Mhz		:  STD_LOGIC;
SIGNAL	GTX_100_CLK		:  STD_LOGIC;
SIGNAL	FEMB_CONV_CLK	:  STD_LOGIC;
SIGNAL 	GLB_i_RESET		: STD_LOGIC;
SIGNAL 	GLB_RESET		: STD_LOGIC;
SIGNAL 	REG_RESET		: STD_LOGIC;
SIGNAL 	UDP_RESET		: STD_LOGIC;
SIGNAL 	ALG_RESET		: STD_LOGIC;
SIGNAL	start_udp_mac	:  STD_LOGIC;


SIGNAL	UDP_FRAME_SIZE				: STD_LOGIC_VECTOR(11 downto 0);
SIGNAL	UDP_TIME_OUT_wait 		: STD_LOGIC_VECTOR(31 downto 0);	
SIGNAL	UDP_header_user_info		: STD_LOGIC_VECTOR(31 downto 0);

SIGNAL	RD_WR_ADDR_SEL	:  STD_LOGIC;
SIGNAL	rd_strb 			:  STD_LOGIC;
SIGNAL	wr_strb 			:  STD_LOGIC;
SIGNAL	WR_address		:  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	RD_address		:  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	data 				:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	rdout 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg0_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg1_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg2_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg3_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg4_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg5_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg6_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg7_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg8_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg9_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg10_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg11_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg12_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg13_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg14_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg15_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg16_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg17_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg18_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg19_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg20_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0):= x"00000020";
SIGNAL	reg21_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg22_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg23_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg24_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg25_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg26_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg27_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg28_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg29_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg30_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg31_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	
-- GXB


SIGNAL	tx_pll_refclk           :  std_logic;
SIGNAL	rx_analogreset          :  std_logic_vector(15 downto 0);
SIGNAL	rx_digitalreset         :  std_logic_vector(15 downto 0);
SIGNAL	rx_cdr_refclk           :  std_logic;	
SIGNAL	tx_std_coreclkin        :  std_logic;
SIGNAL	rx_std_coreclkin        :  std_logic;   --   := (others => 'X'); -- rx_std_coreclkin	
SIGNAL	pll_locked              :  std_logic;   --;                      -- pll_locked
SIGNAL	rx_pma_clkout           :  std_logic;   --;                      -- rx_pma_clkout
SIGNAL	rx_is_lockedtoref       :  std_logic;   --;                      -- rx_is_lockedtoref
SIGNAL	rx_is_lockedtodata      :  std_logic;   --;                      -- rx_is_lockedtodata
SIGNAL	rx_std_clkout           :  std_logic_vector(15 downto 0) ;   --;                      -- rx_std_clkout
SIGNAL	tx_cal_busy             :  std_logic;   --;                      -- tx_cal_busy
SIGNAL	rx_cal_busy             :  std_logic;   --;                      -- rx_cal_busy
SIGNAL	unused_tx_parallel_data :  std_logic_vector(25 downto 0);--  := (others => 'X'); -- unused_tx_parallel_data
SIGNAL	rx_parallel_data        :  std_logic_vector(255 downto 0);                     -- rx_parallel_data

 
SIGNAL	TMP_IO  						: std_logic_vector(31 downto 0);    

SIGNAL	UDP_LATCH 					: std_logic_vector(1 downto 0);    
signal	udp_data						: std_logic_vector(15 downto 0);    
signal	UDP_LATCH_L					: STD_LOGIC;


	
SIGNAL	HEADER_ERROR				: SL_ARRAY_15_TO_0(0 to 1);
SIGNAL	ADC_ERROR					: SL_ARRAY_15_TO_0(0 to 1);
SIGNAL	LINK_SYNC_STATUS			: SL_ARRAY_15_TO_0(0 to 1);
SIGNAL	TIME_STAMP					: SL_ARRAY_15_TO_0(0 to 1);
SIGNAL	CHKSUM_ERROR				: SL_ARRAY_15_TO_0(0 to 1);
SIGNAL	FRAME_ERROR					: SL_ARRAY_15_TO_0(0 to 1);

SIGNAL	link_stat_sel				: std_logic_vector(3 downto 0); 
SIGNAL	TS_latch						: std_logic; 
SIGNAL	ERR_CNT_RST					: std_logic; 

signal	BRD_SEL						: std_logic_vector(3 downto 0); 
signal	BRD_SEL2						: std_logic_vector(3 downto 0); 
signal	CHIP_SEL						: std_logic_vector(3 downto 0); 
signal	CHN_SEL						: std_logic_vector(3 downto 0); 
signal	UDP_DATA_OUT				: SL_ARRAY_15_TO_0(0 to 1);
	
signal	CHIP0_DATA					: std_logic_vector(15 downto 0);  
signal	CHIP1_DATA					: std_logic_vector(15 downto 0);  
signal	CHIP2_DATA					: std_logic_vector(15 downto 0);  
signal	CHIP3_DATA					: std_logic_vector(15 downto 0);  

signal	CHIP0_LATCH					: std_logic;  
signal	CHIP1_LATCH					: std_logic;  
signal	CHIP2_LATCH					: std_logic;  
signal	CHIP3_LATCH					: std_logic;  

SIGNAL	FEMB_BRD						: std_logic_vector(3 downto 0);		
SIGNAL	FEMB_RD_strb				: STD_LOGIC;
SIGNAL	FEMB_WR_strb				: STD_LOGIC;	
SIGNAL	FEMB_RDBK_strb				: STD_LOGIC;
SIGNAL	FEMB_RDBK_DATA				: STD_LOGIC_VECTOR(31 DOWNTO 0);




	

	SIGNAL I2C_WR_STRB		: STD_LOGIC;
	SIGNAL I2C_RD_STRB		: STD_LOGIC;
	SIGNAL I2C_DEV_ADDR		: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL I2C_NUM_BYTES		: STD_LOGIC_VECTOR(3 downto 0);
	SIGNAL I2C_ADDRESS		: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL I2C_DOUT_S1		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL I2C_DIN				: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL I2C_BUSY			: STD_LOGIC;	
	
	
	SIGNAL FEMB_DATA			: SL_ARRAY_15_TO_0(0 to 15);
	SIGNAL RX_FF_EMPTY		: std_logic_vector(15 downto 0);
	SIGNAL RX_FF_RDREQ		: std_logic_vector(15 downto 0);	
	SIGNAL RX_FF_CLK			: STD_LOGIC;	
	SIGNAL RX_FF_RST			: std_logic_vector(15 downto 0);	
	
	
	SIGNAL FEMB_DATA_VALID	: std_logic_vector(15 downto 0);
	SIGNAL FEMB_DATA_CLK		: std_logic_vector(15 downto 0);
	SIGNAL FEMB_EOF			: std_logic_vector(15 downto 0);	
	
	
	

	SIGNAL PWR_MES_RDY				: STD_LOGIC;	
	SIGNAL PWR_MES_OUT				: std_logic_vector(31 downto 0);	
	SIGNAL PWR_MES_SEL				: std_logic_vector(7 downto 0);	
	SIGNAL PWR_MES_start				: STD_LOGIC;	
		
	SIGNAL GXB_analogreset			: STD_LOGIC;	
	SIGNAL GXB_digitalreset			: STD_LOGIC;	
	SIGNAL UDP_EN_WR_RDBK			: STD_LOGIC;	

	SIGNAL TX_PACK_FF_RST			: STD_LOGIC;
	SIGNAL TX_PACK_Stream_EN		: STD_LOGIC;
	SIGNAL tx_analogreset_EN 		: STD_LOGIC;
	SIGNAL tx_digitalreset_EN		: STD_LOGIC;
	SIGNAL pll_powerdown_EN			: STD_LOGIC;
	SIGNAL K_CODE_comma_sym			: std_logic_vector(15 downto 0);	
	SIGNAL HSD_RESET					: STD_LOGIC;
	SIGNAL UDP_DISABLE				: STD_LOGIC;
	
	SIGNAL DEFAULT_DELAY			: std_logic_vector(7 downto 0);	
	SIGNAL POST_TRIGGER			: std_logic_vector(7 downto 0);	
	SIGNAL TRIGGER_MODE			: STD_LOGIC;
	SIGNAL TIME_OUT_wait			: std_logic_vector(31 downto 0);	
	SIGNAL TIME_OUT_wait_send	: std_logic_vector(31 downto 0);	
	SIGNAL BUFFER_DEPTH			: std_logic_vector(7 downto 0);	
	SIGNAL PACKET_RESET			: STD_LOGIC;
	SIGNAL Trigger					: STD_LOGIC;

	
begin


	GLB_i_RESET		<= reg0_P(0);
	REG_RESET		<= GLB_RESET or reg0_P(1);
	UDP_RESET		<= GLB_RESET or reg0_P(2);
	ALG_RESET		<= GLB_RESET or reg0_P(3);
	HSD_RESET		<= GLB_RESET or reg0_P(4);
	PACKET_RESET	<= GLB_RESET or reg0_P(5);
	

	Trigger			<= TRIGGER_IN or reg0_P(6);
	
	BRD_SEL		<= reg7_p(19 DOWNTO 16);
	CHIP_SEL		<= reg7_p(11 DOWNTO 8);
	CHN_SEL		<= reg7_p(3 DOWNTO 0);
	UDP_DISABLE	<= reg7_p(31);

		

	I2C_WR_STRB				<=  reg10_p(0);
	I2C_RD_STRB				<=	 reg10_p(1);
	I2C_NUM_BYTES			<=	reg11_p(3 downto 0);--   : STD_LOGIC_VECTOR(3 downto 0);
	I2C_ADDRESS				<= reg12_p(7 downto 0);--	: STD_LOGIC_VECTOR(7 downto 0);
	reg14_p 					<=	I2C_DOUT_S1; --			: STD_LOGIC_VECTOR(31 downto 0);
	I2C_DIN					<= reg13_p(7 downto 0);--	: STD_LOGIC_VECTOR(7 downto 0);

	GXB_analogreset		<= reg17_p(0);
	GXB_digitalreset		<= reg17_p(1);

	
	link_stat_sel			<= reg18_p(3 downto 0);
	TS_latch					<= reg18_p(8);	
	ERR_CNT_RST				<= reg18_p(15);		


	
	UDP_EN_WR_RDBK			<= reg30_p(0);	
	UDP_FRAME_SIZE			<= reg31_p(11 downto 0);
	TRIGGER_MODE			<= reg31_p(31);
	
	DEFAULT_DELAY			<= reg21_p(7 downto 0);
	POST_TRIGGER			<= reg21_p(15 downto 8);
	BUFFER_DEPTH			<= reg21_p(23 downto 16);
	
	TIME_OUT_wait			<= reg22_p(31 downto 0);

	
WIB_PLL_SYS_inst :  WIB_PLL_SYS 
PORT MAP(	
			refclk   	=> clkin_50_top,
			rst      	=> '0',
			outclk_0 	=> clk_125Mhz,
			outclk_1 	=>	open,
			outclk_2 	=> clk_100Mhz,
			outclk_3		=> clk_50Mhz,
			outclk_4		=> clk_40Mhz
	);

	
SYSTEM_SYNC_PLL_inst : SYSTEM_SYNC_PLL
		port MAP (
			refclk   => clkin_50_top,
			rst      => '0',
			outclk_0 => GTX_100_CLK,
			outclk_1 => open,
			outclk_2 => open,
			locked   => open
		);



SBND_PWM_CLK_ENCODER_INST : ENTITY WORK.SBND_PWM_CLK_ENCODER
	PORT map
	(	
			RESET				=> ALG_RESET,
			CLK_100MHz		=> GTX_100_CLK,
			SAMPLE_RATE		=> X"0",		
			EXT_CMD1			=> '0',		--  bring to pin for external cal pulse
			EXT_CMD2			=> '0',
			EXT_CMD3			=> '0',
			EXT_CMD4			=> '0',	
			SW_CMD1			=> reg16_p(0),	 -- calibration
			SW_CMD2			=> reg16_p(1),
			SW_CMD3			=> reg16_p(2),
			SW_CMD4			=> reg16_p(3),
			DIS_CMD1			=> reg16_p(4),
			DIS_CMD2			=> '0',
			DIS_CMD3			=> '0',
			DIS_CMD4			=> '0',			
			SBND_SYNC_CMD	=> FEMB_CONV_CLK,
			SBND_ADC_CLK	=> open				
	);


	SBND_CLK_FPGA_OUT	 	<= GTX_100_CLK;
	SYS_CMD_FPGA_OUT		<= FEMB_CONV_CLK;
--	LEMO_IN1					<= FEMB_CONV_CLK;
	

	
SYS_RST_inst : sys_rst
PORT MAP(	clk 		=> clkin_50_top,
				reset_in => GLB_i_RESET,
				start 	=> start_udp_mac,
				RST_OUT 	=> GLB_RESET);
				

				

io_registers_inst : entity work.io_registers
PORT MAP(	rst 			=> REG_RESET,
				Ver_ID		=> x"00000105",
				clk 			=> clk_100Mhz,
				WR 			=> wr_strb,
				WR_address 	=> WR_address,
				RD_address 	=> RD_address,
				RD_WR_ADDR_SEL => RD_WR_ADDR_SEL,
				data 			=> data,
				data_out => rdout,
				reg0_i 	=> reg0_p,
				reg1_i	=> reg1_p,		 
				reg2_i 	=> reg2_p,		 
				reg3_i 	=> reg3_p,
				reg4_i 	=> reg4_p,
				reg5_i 	=> reg5_p,
				reg6_i 	=> reg6_p,
				reg7_i 	=> reg7_p,
				reg8_i 	=> reg8_p,
				reg9_i 	=> reg9_p,
				reg10_i 	=> reg10_p,
				reg11_i 	=> reg11_p,
				reg12_i 	=> reg12_p,
				reg13_i 	=> reg13_p,
				reg14_i 	=> reg14_p,
				reg15_i 	=> reg15_p,
				reg16_i 	=> reg16_p,				
				reg17_i 	=> reg17_p,
				reg18_i 	=> reg18_p,
				reg19_i 	=> reg19_p,
				reg20_i 	=> reg20_p,
				reg21_i 	=> reg21_p,
				reg22_i 	=> reg22_p,
				reg23_i 	=> reg23_p,
				reg24_i 	=> reg24_p,
				reg25_i 	=> reg25_p,
				reg26_i 	=> reg26_p,
				reg27_i 	=> reg27_p,
				reg28_i 	=> reg28_p,
				reg29_i 	=> reg29_p,
				reg30_i 	=> reg30_p,
				reg31_i 	=> reg31_p,
				reg32_i 	=> HEADER_ERROR(1) & HEADER_ERROR(0),		
				reg33_i 	=> ADC_ERROR(1)    & ADC_ERROR(0),
				reg34_i 	=> LINK_SYNC_STATUS(1) & LINK_SYNC_STATUS(0),
				reg35_i 	=> TIME_STAMP(1)   & TIME_STAMP(0),	
				reg36_i 	=> CHKSUM_ERROR(1) & CHKSUM_ERROR(0),
				reg37_i 	=> FRAME_ERROR(1)  &	FRAME_ERROR(0), 			
				reg38_i 	=> x"00000000",	
				reg39_i 	=> x"00000000",
				reg40_i 	=> x"00000000",
				reg41_i 	=> x"00000000",	
				reg42_i 	=> x"00000000",
				reg43_i 	=> x"00000000",
				
				reg0_o => reg0_p,
				reg1_o => reg1_p,				
				reg2_o => reg2_p,		
				reg3_o => reg3_p,		
				reg4_o => reg4_p,
				reg5_o => reg5_p,
				reg6_o => open,
				reg7_o => reg7_p,
				reg8_o => reg8_p,
				reg9_o => reg9_p,		
				reg10_o => reg10_p,
				reg11_o => reg11_p,
				reg12_o => reg12_p,
				reg13_o => reg13_p,
				reg14_o => open,
				reg15_o => reg15_p,
				reg16_o => reg16_p,				
				reg17_o => reg17_p,
				reg18_o => reg18_p,
				reg19_o => reg19_p,
				reg20_o => reg20_p,
				reg21_o => reg21_p,
				reg22_o => reg22_p,
				reg23_o => reg23_p,
				reg24_o => reg24_p,
				reg25_o => reg25_p,
				reg26_o => reg26_p,
				reg27_o => reg27_p,
				reg28_o => reg28_p,
				reg29_o => reg29_p,
				reg30_o => reg30_p ,
				reg31_o => reg31_p);
			
	
	
  SBND_HSRX_inst :  entity work.SBND_HSRX_EMU 
	PORT MAP
	(
			RESET						=> HSD_RESET,
			SYS_CLK					=> clk_100Mhz,
			FEMB_GXB_RX				=> FEMB_GXB_RX(3 downto 0),
			GXB_analogreset		=> GXB_analogreset,
			GXB_digitalreset		=> GXB_digitalreset,
			GXB_refclk				=> refclk3R,		
			
			UDP_DISABLE				=> UDP_DISABLE,
			UDP_DATA_OUT			=>	UDP_DATA_OUT(0),			
			UDP_LATCH				=> UDP_LATCH(0),	
	

			FEMB_EOF					=>	FEMB_EOF(7 downto 0),
			RX_FF_DATA				=>	FEMB_DATA(0 to 7),
			RX_FF_EMPTY				=> RX_FF_EMPTY(7 downto 0),
			RX_FF_RDREQ				=> RX_FF_RDREQ(7 downto 0),	
			RX_FF_RST				=> RX_FF_RST(15 downto 8),	
			RX_FF_CLK				=> RX_FF_CLK,
					
			
			BRD_SEL					=>	BRD_SEL,		
			CHIP_SEL					=> CHIP_SEL,
			CHN_SEL					=> CHN_SEL,			

			LINK_DISABLE   		=> x"00",		
			Test_DATA				=>	x"0000",
			
			
			ERR_CNT_RST				=> ERR_CNT_RST,			
			link_stat_sel			=> link_stat_sel,
			TS_latch					=> TS_latch,
			LINK_SYNC_STATUS		=>	LINK_SYNC_STATUS(0), 							 
			TIME_STAMP				=> TIME_STAMP(0),
			CHKSUM_ERROR			=> CHKSUM_ERROR(0),
			FRAME_ERROR				=>	FRAME_ERROR(0),
			HEADER_ERROR			=>	HEADER_ERROR(0),
			ADC_ERROR				=> ADC_ERROR(0),
			
			UDP_DATA_OUT1			=> CHIP0_DATA,
			UDP_DATA_OUT2			=> CHIP2_DATA,
			UDP_DATA_OUT3			=> open,
			UDP_DATA_OUT4			=> open,
			UDP_DATA_OUT5			=> CHIP1_DATA,
			UDP_DATA_OUT6			=> CHIP3_DATA,
			UDP_DATA_OUT7			=> open,
			UDP_DATA_OUT8			=> open,
			
		   UDP_LATCH1				=> CHIP0_LATCH,	
		   UDP_LATCH2				=> CHIP2_LATCH,
		   UDP_LATCH3				=> open,
		   UDP_LATCH4				=> open,
		   UDP_LATCH5				=> CHIP1_LATCH,
		   UDP_LATCH6				=> CHIP3_LATCH,
		   UDP_LATCH7				=> open,
		   UDP_LATCH8				=> open
	);

	
	
udp_data		<= UDP_DATA_OUT(0) when (BRD_SEL = x"0" or BRD_SEL = x"1") else
					UDP_DATA_OUT(1);
					
UDP_LATCH_L	<= UDP_LATCH(0) when (BRD_SEL = x"0" or BRD_SEL = x"1") else
					UDP_LATCH(1);

TIME_OUT_wait_send <= TIME_OUT_wait when( TRIGGER_MODE = '1' ) else x"00001000";

udp_io_inst_Chip0_and_config : entity work.udp_io
PORT MAP(
				reset 				=> UDP_RESET,
				CLK_125Mhz 			=> SFP_CLK,
				CLK_50MHz 			=> clk_50Mhz,
				CLK_IO 				=> clk_100Mhz,	
				
				SPF_OUT 				=> P22_rx,
				SFP_IN 				=> P22_tx,
				
				START 				=> start_udp_mac,			
				BRD_IP				=> x"C0A87901",
				BRD_MAC				=> x"AABBCCDDEE10",
				EN_WR_RDBK			=> UDP_EN_WR_RDBK,
				TIME_OUT_wait 		=> TIME_OUT_wait_send,
				FRAME_SIZE			=> UDP_FRAME_SIZE,
				
				tx_fifo_clk 		=> clk_100Mhz,	
				tx_fifo_wr 			=> CHIP0_LATCH,
				tx_fifo_in 			=> CHIP0_DATA,
				tx_fifo_full		=> open,
				tx_fifo_used		=> open,
				
				header_user_info 	=> reg29_p & reg28_p,					
				system_status 		=> x"000000" & B"000" & TRIGGER_MODE & x"0",
				
				data 					=> data,			
				rdout 				=> rdout,
				wr_strb 				=> wr_strb,
				rd_strb 				=> rd_strb,
				WR_address 			=> WR_address,
				RD_address 			=> RD_address,
				RD_WR_ADDR_SEL		=> RD_WR_ADDR_SEL,
				
				FEMB_BRD				=> FEMB_BRD,
				FEMB_RD_strb		=> FEMB_RD_strb,
				FEMB_WR_strb		=> FEMB_WR_strb,
				FEMB_RDBK_strb		=> FEMB_RDBK_strb,
				FEMB_RDBK_DATA		=> FEMB_RDBK_DATA,	
				
				PACKET_RESET		=> PACKET_RESET,
				
				DEFAULT_DELAY		=> DEFAULT_DELAY,	
				POST_TRIGGER		=> POST_TRIGGER,
				
				TRIGGER_IN			=>	Trigger,
				TRIGGER_MODE		=> TRIGGER_MODE,
				BUFFER_DEPTH		=> BUFFER_DEPTH
	);				
	
	
udp_io_inst_Chip1 : entity work.udp_io
PORT MAP(
				reset 				=> UDP_RESET,
				CLK_125Mhz 			=> SFP_CLK,
				CLK_50MHz 			=> clk_50Mhz,
				CLK_IO 				=> clk_100Mhz,	
				
				SPF_OUT 				=> P20_rx,
				SFP_IN 				=> P20_tx,
				
				START 				=> start_udp_mac,			
				BRD_IP				=> x"C0A87902",
				BRD_MAC				=> x"AABBCCDDEE11",
				EN_WR_RDBK			=> UDP_EN_WR_RDBK,
				TIME_OUT_wait 		=> TIME_OUT_wait_send,	
				FRAME_SIZE			=> UDP_FRAME_SIZE,
				
				tx_fifo_clk 		=> clk_100Mhz,	
				tx_fifo_wr 			=> CHIP1_LATCH,
				tx_fifo_in 			=> CHIP1_DATA,
				tx_fifo_full		=> open,
				tx_fifo_used		=> open,
				
				header_user_info 	=> reg29_p & reg28_p,					
				system_status 		=> x"000000" & B"000" & TRIGGER_MODE & x"1",
				
				data 					=> open,			
				rdout 				=> rdout,
				wr_strb 				=> open,
				rd_strb 				=> open,
				WR_address 			=> open,
				RD_address 			=> open,
				RD_WR_ADDR_SEL		=> open,
				
				FEMB_BRD				=> open,
				FEMB_RD_strb		=> open,
				FEMB_WR_strb		=> open,
				FEMB_RDBK_strb		=> '0',
				FEMB_RDBK_DATA		=> FEMB_RDBK_DATA,
				
				PACKET_RESET		=> PACKET_RESET,
			
				DEFAULT_DELAY		=> DEFAULT_DELAY,	
				POST_TRIGGER		=> POST_TRIGGER,
			
				TRIGGER_IN			=>	Trigger,
				TRIGGER_MODE		=> TRIGGER_MODE,
				BUFFER_DEPTH		=> BUFFER_DEPTH
	);			
	
	
udp_io_inst_Chip2 : entity work.udp_io
PORT MAP(
				reset 				=> UDP_RESET,
				CLK_125Mhz 			=> SFP_CLK,
				CLK_50MHz 			=> clk_50Mhz,
				CLK_IO 				=> clk_100Mhz,	
				
				SPF_OUT 				=> P23_rx,
				SFP_IN 				=> P23_tx,
				
				START 				=> start_udp_mac,			
				BRD_IP				=> x"C0A87903",
				BRD_MAC				=> x"AABBCCDDEE12",
				EN_WR_RDBK			=> UDP_EN_WR_RDBK,
				TIME_OUT_wait 		=> TIME_OUT_wait_send,
				FRAME_SIZE			=> UDP_FRAME_SIZE,
				
				tx_fifo_clk 		=> clk_100Mhz,	
				tx_fifo_wr 			=> CHIP2_LATCH,
				tx_fifo_in 			=> CHIP2_DATA,
				tx_fifo_full		=> open,
				tx_fifo_used		=> open,
				
				header_user_info 	=> reg29_p & reg28_p,					
				system_status 		=> x"000000" & B"000" & TRIGGER_MODE & x"2",
				
				data 					=> open,			
				rdout 				=> rdout,
				wr_strb 				=> open,
				rd_strb 				=> open,
				WR_address 			=> open,
				RD_address 			=> open,
				RD_WR_ADDR_SEL		=> open,
				
				FEMB_BRD				=> open,
				FEMB_RD_strb		=> open,
				FEMB_WR_strb		=> open,
				FEMB_RDBK_strb		=> '0',
				FEMB_RDBK_DATA		=> FEMB_RDBK_DATA,
				
				PACKET_RESET		=> PACKET_RESET,
			
				DEFAULT_DELAY		=> DEFAULT_DELAY,	
				POST_TRIGGER		=> POST_TRIGGER,
				
				TRIGGER_IN			=>	Trigger,
				TRIGGER_MODE		=> TRIGGER_MODE,
				BUFFER_DEPTH		=> BUFFER_DEPTH
	);		
			
udp_io_inst_Chip3 : entity work.udp_io
PORT MAP(
				reset 				=> UDP_RESET,
				CLK_125Mhz 			=> SFP_CLK,
				CLK_50MHz 			=> clk_50Mhz,
				CLK_IO 				=> clk_100Mhz,	
				
				SPF_OUT 				=> P21_rx,
				SFP_IN 				=> P21_tx,
				
				START 				=> start_udp_mac,			
				BRD_IP				=> x"C0A87904",
				BRD_MAC				=> x"AABBCCDDEE13",
				EN_WR_RDBK			=> UDP_EN_WR_RDBK,
				TIME_OUT_wait 		=> TIME_OUT_wait_send,
				FRAME_SIZE			=> UDP_FRAME_SIZE,
				
				tx_fifo_clk 		=> clk_100Mhz,	
				tx_fifo_wr 			=> CHIP3_LATCH,
				tx_fifo_in 			=> CHIP3_DATA,
				tx_fifo_full		=> open,
				tx_fifo_used		=> open,
				
				header_user_info 	=> reg29_p & reg28_p,	
				system_status 		=> x"000000" & B"000" & TRIGGER_MODE & x"3",
				
				data 					=> open,			
				rdout 				=> rdout,
				wr_strb 				=> open,
				rd_strb 				=> open,
				WR_address 			=> open,
				RD_address 			=> open,
				RD_WR_ADDR_SEL		=> open,
				
				FEMB_BRD				=> open,
				FEMB_RD_strb		=> open,
				FEMB_WR_strb		=> open,
				FEMB_RDBK_strb		=> '0',
				FEMB_RDBK_DATA		=> FEMB_RDBK_DATA,
				
				PACKET_RESET		=> PACKET_RESET,
			
				DEFAULT_DELAY		=> DEFAULT_DELAY,	
				POST_TRIGGER		=> POST_TRIGGER,
				
				TRIGGER_IN			=>	Trigger,
				TRIGGER_MODE		=> TRIGGER_MODE,
				BUFFER_DEPTH		=> BUFFER_DEPTH
	);			


	WIB_FEMB_COMM_TOP_INST : ENTITY WORK.WIB_FEMB_COMM_TOP_EMU
	PORT MAP
	(
		RESET   	   			=> ALG_RESET,
		SYS_CLK	   			=> clk_100Mhz,
						
		FEMB_wr_strb 			=> FEMB_WR_strb,
		FEMB_rd_strb 			=> FEMB_RD_strb,
		FEMB_address 			=> WR_address,
		FEMB_BRD					=> FEMB_BRD,
		FEMB_DATA_TO_FEMB		=> data,
		FEMB_DATA_RDY			=> FEMB_RDBK_strb,
		FEMB_DATA_FRM_FEMB	=> FEMB_RDBK_DATA	,
		
		FEMB_SCL_BRD0			=> FEMB_SCL_BRD0,
		FEMB_SDA_BRD0_P		=> FEMB_SDA_BRD0_P,
		FEMB_SDA_BRD0_N		=> FEMB_SDA_BRD0_N

	);	
					
				
	
	
end WIB_EMULATOR_FPGA_ARCH;
