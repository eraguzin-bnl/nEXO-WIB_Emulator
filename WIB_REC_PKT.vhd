
--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: WIB_REC_PKT.VHD            
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 09/14/2016 
--////  Description:   NEEDS SOME more WORK  !!!!!!!!!!!!!!
--////					
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2016 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////

library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
USE work.SbndPkg.all;


entity WIB_REC_PKT is
			generic ( 
							Frame_size  		: integer := 29;
							TIME_OUT		  		: integer := 28  -- use system clock  
						);	
	PORT
	(
		RESET		     	: IN STD_LOGIC;				-- reset		
		CLK		    	: IN STD_LOGIC;				-- GXB RECV CLOCK
		SYS_CLK			: IN STD_LOGIC;				-- SYSTEM CLOCK    link disable and watchdog err counting
		LINK_DISABLE   : IN STD_LOGIC;
		Test_DATA		: IN STD_LOGIC_VECTOR(15 downto 0);		-- will be used with sys_clk and link disable.
		DATA_IN			: IN STD_LOGIC_VECTOR(15 downto 0);		
		PKT_SOF		   : IN STD_LOGIC;
		DATA_VALID	   : IN STD_LOGIC;		

		ERR_CNT_RST		: IN STD_LOGIC;	
		CHKSUM_ERROR	: OUT STD_LOGIC_VECTOR(15 downto 0);		
		FRAME_ERROR		: OUT STD_LOGIC_VECTOR(15 downto 0);
		HEADER_ERROR	: OUT STD_LOGIC_VECTOR(15 downto 0);
		ADC_ERROR		: OUT STD_LOGIC_VECTOR(15 downto 0);
		TIME_STAMP		: OUT STD_LOGIC_VECTOR(15 downto 0);
		
		FEMB_EOF			: OUT STD_LOGIC;		
		RX_FF_DATA		: OUT STD_LOGIC_VECTOR(15 downto 0);
		RX_FF_EMPTY		: OUT STD_LOGIC;
		RX_FF_RDREQ		: IN STD_LOGIC;
		RX_FF_CLK		: IN STD_LOGIC;	
		RX_FF_RST		: IN STD_LOGIC;	

		UDP_DISABLE		: IN STD_LOGIC;			
		CHN_SEL			: IN STD_LOGIC_VECTOR(3 downto 0);
		CHIP_SEL			: IN STD_LOGIC_VECTOR(3 downto 0);
		UDP_LATCH1		: OUT STD_LOGIC;
		UDP_LATCH2		: OUT STD_LOGIC;
		UDP_DATA1		: OUT STD_LOGIC_VECTOR(15 downto 0);
		UDP_DATA2		: OUT STD_LOGIC_VECTOR(15 downto 0)

	);
end WIB_REC_PKT;


architecture WIB_REC_PKT_arch of WIB_REC_PKT is


	TYPE 	 	state_type is (S_IDLE, S_START_Of_FRAME);
	SIGNAL 	state				: state_type;
	SIGNAL 	WORD_CNT			: integer range 63 downto 0;			

	
	SIGNAL	CHECKSUM			: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	CHECKSUM_i		: STD_LOGIC_VECTOR(23 downto 0);	
	SIGNAL	CHKSUM_ERROR_i	: STD_LOGIC;
	SIGNAL	FRAME_ERROR_i	: STD_LOGIC;	

	SIGNAL	CS_ERROR_CNT	: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	FRM_ERROR_CNT	: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	PKT_LATCH_i		: STD_LOGIC;	
	SIGNAL	FRM_E_S1			: STD_LOGIC;	
	SIGNAL	FRM_E_S2			: STD_LOGIC;	
	SIGNAL	CSUM_S1			: STD_LOGIC;	
	SIGNAL	CSUM_S2			: STD_LOGIC;	


	SIGNAL 	UDP_DATA_VALID1: STD_LOGIC;
	SIGNAL 	UDP_DATA_VALID2: STD_LOGIC;
	SIGNAL 	UDP_DATA_I		: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	FF_UDP_empty1	: STD_LOGIC;		
	SIGNAL	FF_UDP_empty2	: STD_LOGIC;
	
	SIGNAL	CHP_STRM_SEL	: STD_LOGIC;
	SIGNAL	CHP_STRM_SEL_S	: STD_LOGIC;		
	
	SIGNAL	CHECKSUM_IN		: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	TIME_STAMP_IN	: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	ADC_ERROR_IN	: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	RESERVED_IN		: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	HEADER_IN		: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	UDP_DISABLE_s	: STD_LOGIC;		

	
	SIGNAL	HEADER_ERROR_i : STD_LOGIC;		
	SIGNAL	ADC_ERROR_i		: STD_LOGIC;		
	SIGNAL	HDR_E_S1			: STD_LOGIC;		
	SIGNAL	HDR_E_S2			: STD_LOGIC;		
	SIGNAL	ADC_E_S1			: STD_LOGIC;		
	SIGNAL	ADC_E_S2			: STD_LOGIC;		
	SIGNAL	ADC_ERROR_CNT	: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	HDR_ERROR_CNT	: STD_LOGIC_VECTOR(15 downto 0);	
	

	SIGNAL	FEMB_DATA_VALID : STD_LOGIC;	
	SIGNAL	FEMB_DATA		 : STD_LOGIC_VECTOR(15 downto 0);	
	
	SIGNAL	DATA_VALID_dly	 : STD_LOGIC;
	
begin
		
	
	
	
	
 process(RX_FF_CLK) 
 begin
		if (RX_FF_CLK'event AND RX_FF_CLK = '1') then
				FEMB_EOF	<= PKT_LATCH_i;
		end if;
end process;


	
 process(CLK) 
 begin
		if (CLK'event AND CLK = '1') then
				FEMB_DATA	<= DATA_IN;
				DATA_VALID_dly <= DATA_VALID;
		end if;
end process;





CHP_STRM_SEL	<= 	'0'	 WHEN  (CHIP_SEL = X"0") ELSE
							'1'	 WHEN  (CHIP_SEL = X"1") ELSE
							'0'	 WHEN  (CHIP_SEL = X"2") ELSE
							'1'	 WHEN  (CHIP_SEL = X"3") ELSE
							'0'	 WHEN  (CHIP_SEL = X"4") ELSE
							'1'	 WHEN  (CHIP_SEL = X"5") ELSE
							'0'	 WHEN  (CHIP_SEL = X"6") ELSE
							'1'	 WHEN  (CHIP_SEL = X"7") ELSE
							'0';
						
	
  process(CLK,RESET) 
  begin
	 if ((RESET = '1') or (LINK_DISABLE = '1')) then
		CHKSUM_ERROR_i		<= '0';
		FRAME_ERROR_i		<= '0';
		ADC_ERROR_i	 		<= '0';		
		HEADER_ERROR_i	 	<= '0';				
		WORD_CNT				<= 0;
		PKT_LATCH_i			<= '0';
		FEMB_DATA_VALID	<= '0';
		UDP_DATA_VALID1		<= '0';
		UDP_DATA_VALID2		<= '0';
		CHECKSUM_i			<=	(others => '0');
		state 				<= S_idle;
		CHP_STRM_SEL_S 	<= '0';
		elsif (CLK'event AND CLK = '1') then

			CASE state IS
			when S_IDLE =>
				CHECKSUM_i			<=	(others => '0');	
				PKT_LATCH_i			<= '0';
				WORD_CNT				<= 0;		
				FRAME_ERROR_i		<= '0';
				FEMB_DATA_VALID	<= '0';
				UDP_DATA_VALID1		<= '0';
				UDP_DATA_VALID2		<= '0';
				if (CHECKSUM  /=  CHECKSUM_IN) then
						CHKSUM_ERROR_i	 <= '1'; 
				end if;					
				if (PKT_SOF  = '1') then
					PKT_LATCH_i				<= '1';		-- latch previous data packet
		--			CHKSUM_ERROR_i			<= '0';
					FRAME_ERROR_i			<= '0';		
					state 					<= S_START_Of_FRAME;		
					CHP_STRM_SEL_S 		<= CHP_STRM_SEL;
					UDP_DISABLE_s			<= UDP_DISABLE;
				end if;		  
		   when S_START_Of_FRAME =>
					PKT_LATCH_i			<= '0';
					FRAME_ERROR_i	 	<= '0';
					CHKSUM_ERROR_i	 	<= '0'; 	
					ADC_ERROR_i	 		<= '0';
					HEADER_ERROR_i	 	<= '0';					
					FEMB_DATA_VALID	<= '0';
					UDP_DATA_VALID1		<= '0';
					UDP_DATA_VALID2		<= '0';		
					if((DATA_VALID = '1') and ( WORD_CNT <= (Frame_size-1))) then
						WORD_CNT 			<= WORD_CNT + 1;	
						UDP_DATA_VALID1		<= '0';
						UDP_DATA_VALID2		<= '0';
						case WORD_CNT IS
							when 0 =>
								CHECKSUM_IN		<= DATA_IN;
							when 1 =>
								TIME_STAMP_IN	<=	DATA_IN;
							when 2 =>
								ADC_ERROR_IN	<= DATA_IN;
							when 3 =>
								RESERVED_IN		<= DATA_IN;
							when 4 =>
								HEADER_IN		<= DATA_IN;
								if(UDP_DISABLE_s = '0') then
									UDP_DATA_VALID1		<= '1';
									UDP_DATA_VALID2		<= '1';
								end if;
								UDP_DATA_I		<= x"FACE";
							when others =>	
								UDP_DATA_I				<= DATA_IN;
								FEMB_DATA_VALID		<= '1';
								if(UDP_DISABLE_s = '1') then
									UDP_DATA_VALID1		<= '0';
									UDP_DATA_VALID2		<= '0';
								elsif(WORD_CNT  < 17) then
									UDP_DATA_VALID1		<= '1';
									UDP_DATA_VALID2		<= '0';
								elsif(WORD_CNT  >= 17) then
									UDP_DATA_VALID1		<= '0';
									UDP_DATA_VALID2		<= '1';
								end if;
						end case; 
						if(WORD_CNT /= 0) then
							CHECKSUM_i	<= CHECKSUM_i + DATA_IN;	
						end if;
					else
						TIME_STAMP	<= TIME_STAMP_IN;
						CHECKSUM		<= (CHECKSUM_i(23 downto 16) + CHECKSUM_i(15 downto 0));	
						if (ADC_ERROR_IN /= x"0000") then
							ADC_ERROR_i	 <= '1';
						end if;			
						if ((HEADER_IN and x"7777") /= x"2222") then   -- remove MSB from header
							HEADER_ERROR_i	 <= '1';
						end if;
						if (WORD_CNT /= Frame_size) then
							FRAME_ERROR_i	 <= '1';
						end if;			
						state 	<= S_IDLE;
					end if;
			when others =>		
				state 	<= S_IDLE;	
			end case; 
	 end if;
end process;




RX_FEMB_UDP_FF_INST1 : entity work.RX_FEMB_UDP_FF
	PORT MAP
	(
	
		data		=> UDP_DATA_I,
		rdclk		=> SYS_CLK,
		rdreq		=> NOT FF_UDP_empty1,
		wrclk		=> CLK,
		wrreq		=> UDP_DATA_VALID1,
		q			=> UDP_DATA1,
		rdempty	=> FF_UDP_empty1
	);
	
	
RX_FEMB_UDP_FF_INST2 : entity work.RX_FEMB_UDP_FF
	PORT MAP
	(
	
		data		=> UDP_DATA_I,
		rdclk		=> SYS_CLK,
		rdreq		=> NOT FF_UDP_empty2,
		wrclk		=> CLK,
		wrreq		=> UDP_DATA_VALID2,
		q			=> UDP_DATA2,
		rdempty	=> FF_UDP_empty2
	);


	
process(SYS_CLK) 
 begin
		if (SYS_CLK'event AND SYS_CLK = '1') then
			UDP_LATCH1	<= not FF_UDP_empty1;
		end if;
end process;	

process(SYS_CLK) 
 begin
		if (SYS_CLK'event AND SYS_CLK = '1') then
			UDP_LATCH2	<= not FF_UDP_empty2;
		end if;
end process;


	RECV_FIFO_inst: entity work.RECV_FIFO
	PORT MAP
	(
		aclr		=> RX_FF_RST,
		data		=> FEMB_DATA,
		rdclk		=> RX_FF_CLK,
		rdreq		=> RX_FF_RDREQ,
		wrclk		=> CLK,
		wrreq		=> FEMB_DATA_VALID,
		q			=> RX_FF_DATA,
		rdempty	=> RX_FF_EMPTY
	);

								
  process(SYS_CLK,RESET,ERR_CNT_RST) 
  begin
	 if ((RESET = '1') or (ERR_CNT_RST = '1')) then

		FRM_E_S1	<= FRAME_ERROR_i;
		FRM_E_S2	<= FRAME_ERROR_i;
		CSUM_S1	<= CHKSUM_ERROR_i;
		CSUM_S2	<= CHKSUM_ERROR_i;
		HDR_E_S1	<= HEADER_ERROR_i;
		HDR_E_S2	<= HEADER_ERROR_i;
		ADC_E_S1	<= ADC_ERROR_i;
		ADC_E_S2	<= ADC_ERROR_i;
		ADC_ERROR_CNT		<= x"0000";
		HDR_ERROR_CNT		<= x"0000";
		CS_ERROR_CNT		<= x"0000";
		FRM_ERROR_CNT		<= x"0000";
     elsif (SYS_CLK'event AND SYS_CLK = '1') then
			FRM_E_S1	<= FRAME_ERROR_i;
			FRM_E_S2	<= FRM_E_S1;
			CSUM_S1	<= CHKSUM_ERROR_i;
			CSUM_S2	<= CSUM_S1;
			HDR_E_S1	<= HEADER_ERROR_i;
			HDR_E_S2	<= HDR_E_S1;
			ADC_E_S1	<= ADC_ERROR_i;
			ADC_E_S2	<= ADC_E_S1;			
			if(FRM_E_S1 = '1' and FRM_E_S2 = '0') then
				FRM_ERROR_CNT	<= FRM_ERROR_CNT + 1;
			end if;
			if(CSUM_S1 = '1' and CSUM_S2 = '0') then
				CS_ERROR_CNT		<= CS_ERROR_CNT	 + 1;
			end if;
			if(HDR_E_S1 = '1' and HDR_E_S2 = '0') then
				HDR_ERROR_CNT		<= HDR_ERROR_CNT	 + 1;
			end if;			
			if(ADC_E_S1 = '1' and ADC_E_S2 = '0') then
				ADC_ERROR_CNT		<= ADC_ERROR_CNT	 + 1;
			end if;							
			CHKSUM_ERROR	<= CS_ERROR_CNT;
			FRAME_ERROR		<= FRM_ERROR_CNT;
			HEADER_ERROR	<= HDR_ERROR_CNT;
			ADC_ERROR		<= ADC_ERROR_CNT;
		end if;
end process;

end WIB_REC_PKT_arch;
