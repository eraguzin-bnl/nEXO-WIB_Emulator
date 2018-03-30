--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: tx_frame.vhd
--////                                                                                                                                      
--////  Author: Jack Fried                                        
--////          jfried@bnl.gov                
--////  Created:  03/22/2014
--////  Modified: 12/11/2014
--////  Description:    This module will form and transmit UDP packets for both
--////                  Register and variable size data packets upto 1024 bytes                     
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2014 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////

library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



--  Entity Declaration

entity tx_frame is
	port
	(
	   clk         		  	: in  std_logic;                     -- Input CLK from MAC Reciever
      reset			        	: in  std_logic;                     -- Synchronous reset signal
		tx_fifo_clk		  	  	: in  std_logic;		
		tx_fifo_in			  	: in  std_logic_vector(15 downto 0);
		tx_fifo_wr		  	  	: in  std_logic;
		tx_fifo_full		  	: out std_logic;  
		tx_fifo_used		   : out STD_LOGIC_VECTOR (11 DOWNTO 0);		

		BRD_IP					: in 	STD_LOGIC_VECTOR(31 downto 0);
		BRD_MAC					: in 	STD_LOGIC_VECTOR(47 downto 0);

		
		ip_dest_addr		  	: in  std_logic_vector(31 downto 0);
		mac_dest_addr		 	: in  std_logic_vector(47 downto 0);
      tx_dst_rdy  	 	  	: in  std_logic;    		-- Input destination ready 
		header_user_info	  	: in  std_logic_vector(63 downto 0);
		
		arp_req				   : in  std_logic;		 -- gen arp_responce
--	   arp_src_IP				: in  std_logic_vector(31 downto 0);
--	   arp_src_MAC			  	: in  std_logic_vector(47 downto 0);

		EN_WR_RDBK				: in  std_logic;    		
		WR_data					: in  std_logic_vector(31 downto 0);
		reg_wr_strb				: in  std_logic;    		-- Input destination ready 
	
		reg_rd_strb				: in  std_logic;    		-- Input destination ready 
		reg_start_address		: in  std_logic_vector(15 downto 0);
		reg_RDOUT_num			: in  std_logic_vector(3 downto 0);   -- number of registers to read out
		reg_address				: out  std_logic_vector(15 downto 0);
		reg_data					: in  std_logic_vector(31 downto 0);
		

		FEMB_BRD					: IN std_logic_vector(3 downto 0);		
		FEMB_RDBK_strb			: IN  STD_LOGIC;
		FEMB_RDBK_DATA			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
		
		
		FRAME_SIZE				: in  std_logic_vector(11 downto 0);  -- 0x1f8
		TIME_OUT_wait			: in  std_logic_vector(31 downto 0);	
 		system_status			: in  std_logic_vector(31 downto 0);	 
		tx_rdy					: IN STD_LOGIC;		
		tx_data_out      		: out std_logic_vector(7 downto 0);  -- Output data
      tx_eop_out       		: out std_logic;                      -- Output end of frame
      tx_sop_out       		: out std_logic;                     -- Output start of frame		
		tx_src_rdy  	  	   : out std_logic;                    -- source ready
		
		PACKET_RESET			: IN  STD_LOGIC;
		
		DEFAULT_DELAY			: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		POST_TRIGGER			: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		TRIGGER_IN				: IN  STD_LOGIC;
		Pre_trigger				: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		TRIGGER_MODE			: IN  STD_LOGIC
      );
end tx_frame;


--  Architecture Body



architecture tx_frame_arch OF tx_frame is
    constant PACKETPERFRAME : std_logic_vector(7 downto 0) := x"01";
    type state_type is (IDLE,TX_HEADER,TX_DATA_LOBYTE,TX_DATA_HIBYTE,TX_ARP,TX_DONE,TX_DONE_WAIT);
    signal state: state_type;
	 
	 type trigger_state_type is (IDLE, TRIGGERED1, TRIGGERED2, TRIGGERED3);
	 signal trigger_state: trigger_state_type;
	 
	 
	 
    signal COUNT_REG 		: std_logic_vector(7 downto 0);	
	 
    signal headersel 		: INTEGER RANGE 0 TO 63;

	 signal packetbytecnt 	: std_logic_vector(15 downto 0);
	 signal packet_cnt		: std_logic_vector(31 downto 0);
	 signal tx_lobyte			: std_logic_vector(7 downto 0);	 
	 
	 
	 signal mac_lentype			: std_logic_vector(15 downto 0);
	 signal ip_version			: std_logic_vector(3 downto 0);
	 signal ip_ihl 				: std_logic_vector(3 downto 0);
	 signal ip_tos					: std_logic_vector(7 downto 0);
	 signal ip_totallen			: std_logic_vector(15 downto 0);		
	 signal ip_ident				: std_logic_vector(15 downto 0);		
	 signal ip_flags				: std_logic_vector(2 downto 0);		
	 signal ip_fragoffset		: std_logic_vector(12 downto 0);		
	 signal ip_ttl					: std_logic_vector(7 downto 0);					
	 signal ip_protocol			: std_logic_vector(7 downto 0);												
	 signal ip_src_addr			: std_logic_vector(31 downto 0);													
	 signal udp_src_port			: std_logic_vector(15 downto 0);							
	 signal udp_dest_port		: std_logic_vector(15 downto 0);			
	
	 signal udp_reg_port			: std_logic_vector(15 downto 0);			
	
	 signal udp_len				: std_logic_vector(15 downto 0);			
	 signal udp_chksum			: std_logic_vector(15 downto 0);				 
	 signal mac_src_addr		   : std_logic_vector(47 downto 0);
	 signal Hchecksum				: std_logic_vector(15 downto 0);
	 signal Hchecksum00			: std_logic_vector(31 downto 0);

	 signal Reg_req				: std_logic;
	 signal FEMB_DS				: std_logic;	 
 	 signal wr_Reg_req			: std_logic;
	 signal Reg_ack				: std_logic;
	 signal reg_data_s		   : std_logic_vector(31 downto 0);
	 signal reg_address_S	   : std_logic_vector(15 downto 0);
	 signal Reg_packet			: std_logic;

	 signal arp_req_S				: std_logic;
	 signal arp_ack				: std_logic;

	 signal	tx_fifo_empty		: std_logic;
	 signal	tx_fifo_rd			: std_logic;
	 signal  tx_fifo_data	   : std_logic_vector(15 downto 0);
	 signal  rd_fifo_used	   : std_logic_vector(11 downto 0);
	 signal  rd_fifo_used_dly  : std_logic_vector(11 downto 0);
	 signal  tx_packet_wait	   : std_logic_vector(31 downto 0); 
 	 signal  packet_size		   : std_logic_vector(15 downto 0);
	 signal  test					: std_logic;
	 signal  IMP_RD_strb			: std_logic;
	 SIGNAL  REG_CNT				: std_logic_vector(3 downto 0);
 	 signal	pkt_wait				: std_logic_vector(7 downto 0);
	 signal  FRAME_SIZE_S		: std_logic_vector(11 downto 0);
	 
	 signal counter				: std_logic_vector(31 downto 0); 
	 signal timeout_counter		: std_logic_vector(31 downto 0); 
	 signal allow_wrreq			: std_logic;
	 signal default_delay_s		: std_logic_vector(31 downto 0); 
	 signal post_trigger_s			: std_logic_vector(31 downto 0); 
	 signal tx_fifo_in_dly		  	: std_logic_vector(15 downto 0);
	 signal tx_fifo_in_actual	  	: std_logic_vector(15 downto 0);
	 signal tx_fifo_wr_actual		: std_LOGIC;
	 signal tx_fifo_wr_dly		: std_LOGIC;
	 
	 signal begin_transmission		: std_LOGIC;
	 
	 signal trigger_buffer		: std_LOGIC;
	 signal trigger_mode_buffer: std_LOGIC;
	 
	 signal packet_reset_s		: std_LOGIC;
	 signal since_last_face		: std_logic_vector(15 downto 0);
	 signal start_face_count	: std_logic;

attribute noprune: boolean;
attribute noprune of since_last_face: signal is true;
attribute noprune of start_face_count: signal is true;
	 
component tx_packet_fifo
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		rdusedw		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
		wrfull		: OUT STD_LOGIC ;
		wrusedw		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
end component;


component edg_det_sync 
	port
	(
      reset			        	: IN  STD_LOGIC;                     -- Synchronous reset signal
		clk		    		  	: IN  STD_LOGIC;                     -- Input CLK  
		signal_in				: IN  STD_LOGIC;							 -- async input signal 
		stb_out					: OUT STD_LOGIC							 -- synchronous output one clock wide when a rising edge occurs on signal in
      );
end component;

	 
BEGIN

	FRAME_SIZE_S <= FRAME_SIZE when ( FRAME_SIZE <= x"F00" and FRAME_SIZE >= x"0ff") else  x"1f8";

						 

	inst_tx_packet_fifo : tx_packet_fifo 
    port map (
   	aclr			=> reset,
		data			=> tx_fifo_in_actual,
		rdclk			=> not clk,
		rdreq			=> tx_fifo_rd,
		wrclk			=> tx_fifo_clk,
		wrreq			=> tx_fifo_wr_actual,
		q				=> tx_fifo_data,
		rdempty		=> tx_fifo_empty,
		rdusedw		=> rd_fifo_used,
		wrfull		=> tx_fifo_full,
		wrusedw		=> tx_fifo_used
    );
		
trigger_machine: process(clk,reset) 

  begin
     if (reset = '1') then
         trigger_state           <= idle;
			counter						<= x"00000000";
			timeout_counter			<= x"00000000";
			begin_transmission		<= '0';
			start_face_count			<= '0';
			since_last_face 			<= x"FFFF";
     elsif (clk'event AND clk = '1') then
	  
		  tx_fifo_in_dly				<= tx_fifo_in;
		  tx_fifo_wr_dly				<= tx_fifo_wr;
		  trigger_buffer				<= TRIGGER_IN;
		  trigger_mode_buffer		<= TRIGGER_MODE;
		  
		  	if (TRIGGER_MODE = '1') then
			
				tx_fifo_in_actual 	<= tx_fifo_in_dly;
				tx_fifo_wr_actual 	<= allow_wrreq and tx_fifo_wr_dly;
				
			elsif	(TRIGGER_MODE = '0') then
			
				tx_fifo_in_actual 	<= tx_fifo_in;
				tx_fifo_wr_actual 	<= tx_fifo_wr;
				
			end if;
			
			
        CASE trigger_state is
		  
          when IDLE =>
				counter 				<= x"00000000";
				since_last_face 			<= x"FFFF";
				start_face_count			<= '0';
				begin_transmission		<= '0';
				if ((trigger_buffer = '1') and (trigger_mode_buffer = '1')) then
					trigger_state			<= TRIGGERED1;
				end if;
				
			 when TRIGGERED1 =>
				timeout_counter	<= timeout_counter + 1;
				
				if (start_face_count = '1') and (tx_fifo_wr = '1') then
					since_last_face <= since_last_face + 1;
				end if;
				
				if (tx_fifo_in_dly = x"FACE") and (tx_fifo_wr_dly = '1') and (since_last_face > x"B") then
					counter <= counter + 1;
					timeout_counter	<= x"00000000";
					start_face_count  <= '1';
					since_last_face 	<= x"0000";
				end if;
				
				--This is to ensure that a start-of-frame "FACE" is the first chunk of data that is latched
				if ((counter > (DEFAULT_DELAY)) and (tx_fifo_in = x"FACE") and (tx_fifo_wr = '1') and (since_last_face > x"A")) then
					allow_wrreq 		<= '1';
					counter 				<= x"00000000";
					timeout_counter	<= x"00000000";
					start_face_count  <= '0';
					since_last_face 	<= x"FFFF";
					trigger_state		<= TRIGGERED2;
				end if;
				
				if (timeout_counter > TIME_OUT_wait) then
					trigger_state		<= IDLE;
					counter 				<= x"00000000";
					timeout_counter	<= x"00000000";
				end if;
				
			 when TRIGGERED2 =>
				timeout_counter	<= timeout_counter + 1;
				
				if (start_face_count = '1') and (tx_fifo_wr = '1') then
					since_last_face <= since_last_face + 1;
				end if;
			 
				if (tx_fifo_in_dly = x"FACE" and (tx_fifo_wr_dly = '1') and (since_last_face > x"B")) then
					counter <= counter + 1;
					timeout_counter	<= x"00000000";
					start_face_count  <= '1';
					since_last_face 	<= x"0000";
				end if;
				
				if (counter > POST_TRIGGER) then
					trigger_state		<= TRIGGERED3;
					counter 				<= x"00000000";
					timeout_counter	<= x"00000000";
					start_face_count  <= '0';
					since_last_face 	<= x"FFFF";
				end if;
				
				if (timeout_counter > TIME_OUT_wait) then
					trigger_state		<= TRIGGERED3;
					counter 				<= x"00000000";
					timeout_counter	<= x"00000000";
					start_face_count  <= '0';
					since_last_face 	<= x"FFFF";
				end if;
					
			  when TRIGGERED3 =>
			  
			   if (tx_fifo_wr_actual = '1') then
					counter <= counter + 1;
				end if;
				
				if (counter > x"A") then
					allow_wrreq				<= '0';
					counter <= counter + 1;
				end if;
				
				if (counter > x"1F") then
					trigger_state			<= IDLE;
					begin_transmission	<= '1';
				end if;
					
			  when others => counter   			<= x"00000000";
								  timeout_counter		<= x"00000000";
								  allow_wrreq			<= '0';
								  trigger_state 		<= IDLE;
								  begin_transmission		<= '0';
			end case;
		end if;
end process trigger_machine;
		
process(clk,reset) 

  begin
	if (clk'event AND clk = '1') then

		ip_src_addr		<= BRD_IP;
		mac_src_addr	<= BRD_MAC;
		Hchecksum00 	<= ((x"0000" & ip_src_addr(15 downto 0)) + (x"0000" & ip_src_addr(31 downto 16))) + ((x"0000" &ip_dest_addr(15 downto 0)) + (x"0000" &ip_dest_addr(31 downto 16)));
		Hchecksum   	<= not (( x"02bc" + ip_totallen(15 downto 0)) + ((Hchecksum00(31 downto 16)) + Hchecksum00(15 downto 0)));
     end if;
  end process;		
		

	reg_address	<=	reg_address_S;
		
			
process(clk,reset,Reg_ack,reg_rd_strb) 

  begin
     if (reset = '1') or (Reg_ack = '1') then
	   Reg_req			<= '0';
		wr_Reg_req		<= '0';
     elsif (clk'event AND clk = '1') then	  
	  
			if (FEMB_RDBK_strb = '1') and (Reg_req = '0')  then
				reg_address_S	<= reg_start_address;
				FEMB_DS	<= '1';
				if    (FEMB_BRD = x"0")  then
					Reg_req			<= '1';	
					wr_Reg_req		<= '1';				
					udp_reg_port	<= x"7D12";
				elsif (FEMB_BRD = x"1")  then
					Reg_req			<= '1';	
					wr_Reg_req		<= '1';						
					udp_reg_port	<= x"7D22";
				elsif (FEMB_BRD = x"2")  then
					Reg_req			<= '1';	
					wr_Reg_req		<= '1';						
					udp_reg_port	<= x"7D32";
				elsif (FEMB_BRD = x"3")  then
					Reg_req			<= '1';	
					wr_Reg_req		<= '1';						
					udp_reg_port	<= x"7D42";
				end if;
			end if;	
			
			if (reg_rd_strb = '1') and (Reg_req = '0') then
				reg_address_S	<= reg_start_address;
				udp_reg_port	<=  x"7D02";
				Reg_req			<= '1';	
				wr_Reg_req		<= '0';
			end if;	
			if (reg_wr_strb = '1') and (Reg_req = '0') and (EN_WR_RDBK = '1') then
				FEMB_DS			<= '0';
				reg_address_S	<= reg_start_address;
				udp_reg_port	<=  x"7D02";
				Reg_req			<= '1';	
				wr_Reg_req		<= '1';
			end if;	
			if( headersel = 44) and (wr_Reg_req = '0') and (Reg_packet = '1')  then
				reg_address_S	<= reg_address_S + 1;
		   end if;
	  end if;
  end process;
  
	
	


  process(clk) 
  begin
     if (clk'event AND clk = '1') then
			rd_fifo_used_dly	 	<= rd_fifo_used; 
     end if;
  end process;	
		
		
		
		
process(clk,reset,arp_req,arp_ack) 

  begin
     if (reset = '1') or (arp_ack = '1') then
			arp_req_S	<= '0';
     elsif (clk'event AND clk = '1') then
		if (arp_req = '1') then
			arp_req_S			<= '1';
		end if;
     end if;
  end process;	
		
	
			 
machine: process(clk,reset,Reg_req) 

  begin
     if (reset = '1') then
         state              		<= idle;
         tx_data_out     			<= (others => '0'); 
         tx_sop_out    	 			<= '0';
         tx_eop_out    	 			<= '0';
         tx_src_rdy      			<= '0'; 
         headersel          		<=  0;
			packetbytecnt		 		<= (others => '0');
			packet_cnt				 	<= (others => '0');
         mac_lentype             <= x"0800"; 
		   ip_version					<= x"4";
		   ip_ihl						<= x"5";
			ip_tos						<= x"00";
			ip_totallen					<= x"0044";
			ip_ident						<= x"3DAA";
			ip_flags						<= "000";
			ip_fragoffset				<= (others => '0');
			ip_ttl						<= x"80";
			ip_protocol					<= x"11";
			udp_src_port				<= x"7D00";
			udp_dest_port				<= x"7D02";
			udp_len						<= x"0030"; --x"0408" --length of UDP header(src_port, dest_prot, len, chksum) and data
			udp_chksum					<= x"0000"; --set to zero to disable checksumming
			Reg_ack 						<= '1';
			Reg_packet					<= '0';
			tx_packet_wait				<= x"00000000";
			tx_fifo_rd					<= '0';
			packet_size					<= x"0000";
			test							<= '0';
			arp_ack 						<= '0';
			reg_data_s					<= (others => '0');	
			COUNT_REG 					<= x"01";
     elsif (clk'event AND clk = '1') then
        CASE state is
          when IDLE =>
                  
			 		Reg_ack 		 			<= '0';
					arp_ack 					<= '0';					
               tx_eop_out   			<= '0';
               packetbytecnt  		<= (others => '0');
					tx_fifo_rd				<= '0';
					test						<= '0';
					mac_lentype       	<= x"0800"; 
					COUNT_REG 				<= x"00";
					
					packet_reset_s				<= PACKET_RESET;
					if (packet_reset_s = '1') then
						packet_cnt				<= x"00000000";
					end if;
					
               if (Reg_req = '1') then
						Reg_packet			<= '1';
						udp_dest_port		<= udp_reg_port;
						if  (reg_RDOUT_num  = x"00") then 
							ip_totallen			<= x"002e";
							udp_len				<= x"0014";	 -- 1a
							COUNT_REG 			<= x"01";
						else
							COUNT_REG 			<= x"0F";
							ip_totallen			<= x"007D";
							udp_len				<= x"0069";
						end if;					
						tx_data_out 		<= mac_dest_addr(47 downto 40);						
						headersel 			<= 0;
						state 				<= tx_header;						
					elsif(arp_req_S = '1') then
						mac_lentype       <= x"0806"; 
						arp_ack 				<= '1';
						state 				<= TX_ARP;	
					elsif (tx_fifo_empty = '0') then
						if( rd_fifo_used >= FRAME_SIZE_S) then -- changed 2/21/2012 from >= 200  0x1f8
								tx_packet_wait		<= x"00000000";
								Reg_packet			<= '0';
								packet_cnt 			<= packet_cnt + 1;
								ip_totallen			<= (b"000" & FRAME_SIZE_S & '0') + 32 + 12;
								udp_len				<= (b"000" & FRAME_SIZE_S & '0') + 12 + 12;
								packet_size			<=  b"000" & FRAME_SIZE_S & '0';
								tx_data_out 		<= mac_dest_addr(47 downto 40);
								udp_dest_port		<= x"7D03";
								headersel 			<= 0;
								state 				<= tx_header;					
						elsif((tx_packet_wait >  TIME_OUT_wait) or (begin_transmission = '1')) then
							if (rd_fifo_used_dly  = rd_fifo_used) then
									test					<= '1';
									tx_packet_wait		<= x"00000000";
									Reg_packet			<= '0';
									packet_cnt 			<= packet_cnt + 1;
									ip_totallen			<= (b"000" & rd_fifo_used & '0') + 32 + 12;
									udp_len				<= (b"000" & rd_fifo_used & '0')  + 12 + 12;
									packet_size			<=  b"000" & rd_fifo_used & '0' ;
									tx_data_out 		<= mac_dest_addr(47 downto 40);
									udp_dest_port		<= x"7D03";
									headersel 			<= 0;
									state 				<= tx_header;
							else
									tx_packet_wait		<= x"00000000";
							end if;
						elsif(rd_fifo_used_dly  = rd_fifo_used) then
							tx_packet_wait <= tx_packet_wait  +1;
						else
							tx_packet_wait		<= x"00000000";
						end if;
					end if;
           when TX_HEADER =>
			      headersel <= headersel + 1;
					case headersel is 
					   when 0 =>      tx_data_out <= mac_dest_addr(47 downto 40);
											tx_sop_out  <= '1';
											tx_src_rdy  <= '1';						
					   when 1 =>      tx_data_out <= mac_dest_addr(39 downto 32);
											tx_sop_out  <= '0';
						when 2 =>      tx_data_out <= mac_dest_addr(31 downto 24);
					   when 3 =>      tx_data_out <= mac_dest_addr(23 downto 16);
					   when 4 =>      tx_data_out <= mac_dest_addr(15 downto 8);
					   when 5 =>      tx_data_out <= mac_dest_addr(7 downto 0);
					   when 6 =>      tx_data_out <= mac_src_addr(47 downto 40);
					   when 7 =>      tx_data_out <= mac_src_addr(39 downto 32);
					   when 8 =>      tx_data_out <= mac_src_addr(31 downto 24);
					   when 9 =>      tx_data_out <= mac_src_addr(23 downto 16);
					   when 10 =>     tx_data_out <= mac_src_addr(15 downto 8);
					   when 11 =>     tx_data_out <= mac_src_addr(7 downto 0);   
					   when 12 =>     tx_data_out <= mac_lentype(15 downto 8);
					   when 13 =>     tx_data_out <= mac_lentype(7 downto 0); 
						when 14 => 		tx_data_out <= ip_version(3 downto 0) & ip_ihl(3 downto 0);
						when 15 =>     tx_data_out <= ip_tos(7 downto 0);
						when 16 => 		tx_data_out <= ip_totallen(15 downto 8);
						when 17 =>     tx_data_out <= ip_totallen(7 downto 0);	
						when 18 => 		tx_data_out <= ip_ident(15 downto 8);
						when 19 =>     tx_data_out <= ip_ident(7 downto 0);		
						when 20 => 		tx_data_out <= ip_flags(2 downto 0) & ip_fragoffset(12 downto 8);
						when 21 =>     tx_data_out <= ip_fragoffset(7 downto 0);	
						when 22 =>     tx_data_out <= ip_ttl(7 downto 0);
						when 23 =>     tx_data_out <= ip_protocol(7 downto 0);
						when 24 =>     tx_data_out <= Hchecksum(15 downto 8);
						when 25 =>     tx_data_out <= Hchecksum(7 downto 0);		
					   when 26 =>     tx_data_out <= ip_src_addr(31 downto 24);
					   when 27 =>     tx_data_out <= ip_src_addr(23 downto 16);
					   when 28 =>     tx_data_out <= ip_src_addr(15 downto 8);
					   when 29 =>     tx_data_out <= ip_src_addr(7 downto 0);  
					   when 30 =>     tx_data_out <= ip_dest_addr(31 downto 24);
					   when 31 =>     tx_data_out <= ip_dest_addr(23 downto 16);
					   when 32 =>     tx_data_out <= ip_dest_addr(15 downto 8);
					   when 33 =>     tx_data_out <= ip_dest_addr(7 downto 0);  
					   when 34 =>     tx_data_out <= udp_src_port(15 downto 8);
					   when 35 =>     tx_data_out <= udp_src_port(7 downto 0);  						
					   when 36 =>     tx_data_out <= udp_dest_port(15 downto 8);
					   when 37 =>     tx_data_out <= udp_dest_port(7 downto 0);  	
					   when 38 =>     tx_data_out <= udp_len(15 downto 8);
					   when 39 =>     tx_data_out <= udp_len(7 downto 0);
					   when 40 =>     tx_data_out <= udp_chksum(15 downto 8);
					   when 41 =>     tx_data_out <= udp_chksum(7 downto 0);	
						when 42 =>  if (Reg_packet = '1') then 
											if(wr_Reg_req = '0') then
												reg_data_s	<= reg_data;	
											else
												if (FEMB_DS = '0') then
													reg_data_s	<= WR_data;	
												else
													reg_data_s	<= FEMB_RDBK_DATA;	
												end if;
												COUNT_REG 	<= x"00";
											end if;
											tx_data_out <= reg_address_S(15 downto 8);
										else
											tx_data_out <= x"DE";	--				tx_data_out <= packet_cnt(31 downto 24);
										end if;	
						when 43 => if (Reg_packet = '1') then 
											tx_data_out <= reg_address_S(7 downto 0);
										else     
											tx_data_out <= x"AD";
										end if;
						when 44 => if (Reg_packet = '1') then 
											tx_data_out 	<= reg_data_s(31 downto 24);
										else     
											tx_data_out <= x"BE";
										end if;
										
						when 45 => if (Reg_packet = '1') then 
											tx_data_out <= reg_data_s(23 downto 16);
										else     
											tx_data_out <= x"EF";
										end if;
	
						when 46 => if (Reg_packet = '1') then 
											tx_data_out <= reg_data_s(15 downto 8);
									  else
											tx_data_out <= x"CA";
									  end if;
						when 47 => if (Reg_packet = '1') then 
											tx_data_out <= reg_data_s(7 downto 0);
									  else
											tx_data_out <= x"FE";
									  end if;	
									  COUNT_REG	<= COUNT_REG - 1;
									  if (COUNT_REG /= x"00")  and (Reg_packet = '1') then 
												headersel <= 42;
									  end if;		  
						when 48 => if (Reg_packet = '1') then 
											tx_data_out <= x"0" & reg_RDOUT_num;		
											tx_eop_out  <= '1';
											Reg_ack 		<= '1';
											state 		<= tx_done;		
										else
											tx_data_out <= packet_size(15 downto 8);
										end if;
						when 49 =>		tx_data_out <= packet_size(7 downto 0);
						when 50 =>		tx_data_out <= packet_cnt(31 downto 24);
						when 51 =>		tx_data_out <= packet_cnt(23 downto 16);
						when 52 =>		tx_data_out <= packet_cnt(15 downto 8);
						when 53 =>  	tx_data_out <= packet_cnt(7 downto 0);

						when 54 =>  	tx_data_out <= system_status(7 downto 0);
						when 55 =>  	tx_data_out <= DEFAULT_DELAY(7 downto 0);	
						when 56 =>  	tx_data_out <= Pre_trigger(7 downto 0);
						when 57 =>  	tx_data_out <= POST_TRIGGER(7 downto 0);
											state <= tx_data_hibyte;
											tx_fifo_rd 			<= '1';
						when others => tx_data_out <= x"00";
					                  state <= idle;    
					end case;					
           when TX_DATA_HIBYTE =>
							tx_fifo_rd 			<= '0';
                     tx_data_out		 	<= tx_fifo_data(15 downto 8); 
                     tx_lobyte   		<= tx_fifo_data(7 downto 0);
							packetbytecnt 		<= packetbytecnt + 1;
							state 				<= tx_data_lobyte;
           when TX_DATA_LOBYTE =>
                 if (packetbytecnt  >=  packet_size-2) then
                     tx_data_out 		<=  tx_lobyte; 
                     tx_eop_out  		<= '1';
							tx_fifo_rd 			<= '0';
                     packetbytecnt  	<= (others => '0');
                     state 				<= tx_done;
                 else
							tx_fifo_rd 			<= '1';
                     tx_data_out 		<= tx_lobyte; 
                     packetbytecnt 		<= packetbytecnt + 1;
                     state 				<= tx_data_hibyte;
                 end if;
          when TX_ARP =>
					case headersel is 
					   when 0 =>      tx_data_out <= mac_dest_addr(47 downto 40);
											tx_sop_out  <= '1';
											tx_src_rdy  <= '1';						
					   when 1 =>      tx_data_out <= mac_dest_addr(39 downto 32);
											tx_sop_out  <= '0';
						when 2 =>      tx_data_out <= mac_dest_addr(31 downto 24);
					   when 3 =>      tx_data_out <= mac_dest_addr(23 downto 16);
					   when 4 =>      tx_data_out <= mac_dest_addr(15 downto 8);
					   when 5 =>      tx_data_out <= mac_dest_addr(7 downto 0);
					   when 6 =>      tx_data_out <= mac_src_addr(47 downto 40);
					   when 7 =>      tx_data_out <= mac_src_addr(39 downto 32);
					   when 8 =>      tx_data_out <= mac_src_addr(31 downto 24);
					   when 9 =>      tx_data_out <= mac_src_addr(23 downto 16);
					   when 10 =>     tx_data_out <= mac_src_addr(15 downto 8);
					   when 11 =>     tx_data_out <= mac_src_addr(7 downto 0);   
					   when 12 =>     tx_data_out <= mac_lentype(15 downto 8);
					   when 13 =>     tx_data_out <= mac_lentype(7 downto 0); 
						when 14 => 		tx_data_out <= x"00"; --HW_TYPE  
						when 15 =>     tx_data_out <= x"01"; --HW_TYPE
						when 16 => 		tx_data_out <= x"08"; --protocal type
						when 17 =>     tx_data_out <= x"00"; --protocal type
						when 18 => 		tx_data_out <= x"06"; --HW SIZE
						when 19 =>     tx_data_out <= x"04"; --PROTOCOL size
						when 20 => 		tx_data_out <= x"00"; -- opcode_req
						when 21 =>     tx_data_out <= x"02"; -- opcode req
						when 22 =>     tx_data_out <= mac_src_addr(47 downto 40);
						when 23 =>     tx_data_out <= mac_src_addr(39 downto 32);
						when 24 =>     tx_data_out <= mac_src_addr(31 downto 24);
						when 25 =>     tx_data_out <= mac_src_addr(23 downto 16);
					   when 26 =>     tx_data_out <= mac_src_addr(15 downto 8);
					   when 27 =>     tx_data_out <= mac_src_addr(7 downto 0); 
					   when 28 =>     tx_data_out <= ip_src_addr(31 downto 24);
					   when 29 =>     tx_data_out <= ip_src_addr(23 downto 16);
					   when 30 =>     tx_data_out <= ip_src_addr(15 downto 8);
					   when 31 =>     tx_data_out <= ip_src_addr(7 downto 0);
					   when 32 =>     tx_data_out <= mac_dest_addr(47 downto 40);
					   when 33 =>     tx_data_out <= mac_dest_addr(39 downto 32);
					   when 34 =>     tx_data_out <= mac_dest_addr(31 downto 24);
					   when 35 =>     tx_data_out <= mac_dest_addr(23 downto 16);
					   when 36 =>     tx_data_out <= mac_dest_addr(15 downto 8);
					   when 37 =>     tx_data_out <= mac_dest_addr(7 downto 0);
						when 38 =>     tx_data_out <= ip_dest_addr(31 downto 24);
						when 39 =>     tx_data_out <= ip_dest_addr(23 downto 16);
						when 40 =>     tx_data_out <= ip_dest_addr(15 downto 8);
						when 41 =>     tx_data_out <= ip_dest_addr(7 downto 0);
											tx_eop_out  <= '1';
											state 		<= tx_done;
						when others => tx_data_out <= x"00";
					                  state <= idle;    
					end case;	

					headersel 	<= headersel + 1;				                  
           when TX_DONE =>   
					  arp_ack 		<= '0';
					  Reg_ack 		<= '0';			  
					  tx_eop_out 	<= '0';
                 tx_src_rdy 	<= '0';
                 headersel 	<= 0;
					  pkt_wait		<= x"00";
					  state 			<= TX_DONE_WAIT;	  
				when TX_DONE_WAIT =>	  
						pkt_wait	<= pkt_wait + 1;
						if(pkt_wait >= 20) then
							state 			<= idle;
						end if;		 
					  
			when others => tx_data_out <= x"00";
								Reg_ack 		<= '0';			  
							   tx_eop_out 	<= '0';
							   tx_src_rdy 	<= '0';
							   headersel 	<= 0;
							   state 		<= idle;
        end case;
     end if;
  end process machine;

END tx_frame_arch;
