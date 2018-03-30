--*********************************************************
--* FILE  : IO_registers.VHD
--* Author: Jack Fried
--*
--* Last Modified: 5/19/2013
--*  
--* Description: interface to the TSE UDP IO
--*		 		               
--*
--*
--*********************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;


--  Entity Declaration

ENTITY IO_registers IS

	PORT
	(
		rst             : IN STD_LOGIC;				-- state machine reset
		clk             : IN STD_LOGIC;
		Ver_ID		      : IN STD_LOGIC_VECTOR(31 downto 0);	
		data            : IN STD_LOGIC_VECTOR(31 downto 0);	
		RD_WR_ADDR_SEL	: IN std_logic;	
		WR_address      : IN STD_LOGIC_VECTOR(15 downto 0); 
		RD_address      : IN STD_LOGIC_VECTOR(15 downto 0); 
		WR    	 	      : IN STD_LOGIC;				
		data_out		    : OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg0_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg1_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg2_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg3_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg4_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg5_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg6_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg7_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg8_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg9_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg10_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg11_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg12_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg13_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg14_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg15_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg16_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg17_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg18_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg19_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg20_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg21_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg22_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg23_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg24_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg25_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg26_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg27_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg28_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg29_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg30_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg31_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg32_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg33_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg34_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg35_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg36_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg37_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg38_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg39_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg40_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg41_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg42_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg43_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		
		reg0_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg1_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg2_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg3_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg4_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg5_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg6_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg7_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg8_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg9_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg10_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg11_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg12_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg13_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg14_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg15_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg16_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg17_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg18_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg19_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg20_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg21_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg22_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg23_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg24_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg25_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg26_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg27_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg28_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg29_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg30_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg31_o		: OUT  STD_LOGIC_VECTOR(31 downto 0)
	);
	
END IO_registers;


ARCHITECTURE behavior OF IO_registers IS


begin

  data_out		<=	 reg0_i 	when (RD_address(7 downto 0) = x"00")	else
                   reg1_i 	when (RD_address(7 downto 0) = x"01")	else
                   reg2_i 	when (RD_address(7 downto 0) = x"02")	else
                   reg3_i 	when (RD_address(7 downto 0) = x"03")	else
                   reg4_i 	when (RD_address(7 downto 0) = x"04")	else
                   reg5_i 	when (RD_address(7 downto 0) = x"05")	else
                   reg6_i 	when (RD_address(7 downto 0) = x"06")	else
                   reg7_i 	when (RD_address(7 downto 0) = x"07")	else
                   reg8_i 	when (RD_address(7 downto 0) = x"08")	else
                   reg9_i 	when (RD_address(7 downto 0) = x"09")	else
                   reg10_i	when (RD_address(7 downto 0) = x"0a")	else
                   reg11_i	when (RD_address(7 downto 0) = x"0b")	else
                   reg12_i	when (RD_address(7 downto 0) = x"0c")	else
                   reg13_i	when (RD_address(7 downto 0) = x"0d")	else
                   reg14_i	when (RD_address(7 downto 0) = x"0e")	else
                   reg15_i	when (RD_address(7 downto 0) = x"0f")	else
                   reg16_i	when (RD_address(7 downto 0) = x"10")	else
                   reg17_i	when (RD_address(7 downto 0) = x"11")	else
                   reg18_i	when (RD_address(7 downto 0) = x"12")	else
                   reg19_i	when (RD_address(7 downto 0) = x"13")	else
                   reg20_i	when (RD_address(7 downto 0) = x"14")	else
                   reg21_i	when (RD_address(7 downto 0) = x"15")	else
                   reg22_i	when (RD_address(7 downto 0) = x"16")	else
                   reg23_i	when (RD_address(7 downto 0) = x"17")	else
                   reg24_i	when (RD_address(7 downto 0) = x"18")	else
                   reg25_i	when (RD_address(7 downto 0) = x"19")	else
                   reg26_i	when (RD_address(7 downto 0) = x"1a")	else
                   reg27_i	when (RD_address(7 downto 0) = x"1b")	else
                   reg28_i	when (RD_address(7 downto 0) = x"1c")	else
                   reg29_i	when (RD_address(7 downto 0) = x"1d")	else
                   reg30_i	when (RD_address(7 downto 0) = x"1e")	else
                   reg31_i	when (RD_address(7 downto 0) = x"1f")  else
                   reg32_i	when (RD_address(7 downto 0) = x"20")	else
                   reg33_i	when (RD_address(7 downto 0) = x"21")	else
                   reg34_i	when (RD_address(7 downto 0) = x"22")	else
                   reg35_i	when (RD_address(7 downto 0) = x"23")	else
                   reg36_i	when (RD_address(7 downto 0) = x"24")	else
                   reg37_i	when (RD_address(7 downto 0) = x"25")	else
                   reg38_i	when (RD_address(7 downto 0) = x"26")	else
                   reg39_i	when (RD_address(7 downto 0) = x"27")	else
                   reg40_i	when (RD_address(7 downto 0) = x"28")	else
                   reg41_i	when (RD_address(7 downto 0) = x"29")  else						 
                   reg42_i	when (RD_address(7 downto 0) = x"2A")	else
                   reg43_i	when (RD_address(7 downto 0) = x"2B")  else							 
						 Ver_ID	when (RD_address(7 downto 0) = x"FF")  else					 
                   X"00000000";
	
	
				 
					 
  process(clk,WR,rst) 
  begin
		if (rst = '1') then
			reg0_o		<= X"00000000";		
			reg1_o		<= X"00000000";	
			reg2_o		<= X"00000000";
			reg3_o		<= X"00000000";
			reg4_o		<= X"00000000";
			reg5_o		<= X"00000000";
			reg6_o		<= X"00000000";	
			reg7_o		<= X"00000000";	
			reg8_o		<= X"0001000F";	
			reg9_o		<= X"00000000";	
			reg10_o		<= X"00000000";
			reg11_o		<= X"00000000";	
			reg12_o		<= X"00000000";		
			reg13_o		<= X"00000000";
			reg14_o		<= X"00000000";	
			reg15_o		<= X"00000000";
			reg16_o		<= X"00000000";		
			reg17_o		<= X"00000000";	
			reg18_o		<= X"00000000";
			reg19_o		<= X"00000000";
			reg20_o		<= X"00000000";	
			reg21_o		<= X"0000C5BC";	
			reg22_o		<= X"00000000";	
			reg23_o		<= X"00000000";	
			reg24_o		<= X"00000000";		
			reg25_o		<= X"00000000";
			reg26_o		<= X"00000000";
			reg27_o		<= X"00000000";
			reg28_o		<= X"00000000";		
			reg29_o		<= X"00000000";
			reg30_o		<= X"00000000";
			reg31_o		<= X"00000EFB";
		
		elsif (clk'event  AND  clk = '1') then
			reg0_o			<= X"00000000";	
			if (WR = '1') then
				CASE WR_address(7 downto 0) IS
					when x"00" => 	reg0_o   <= data;
					when x"01" => 	reg1_o   <= data;	
					when x"02" => 	reg2_o   <= data;
					when x"03" => 	reg3_o   <= data;
					when x"04" => 	reg4_o   <= data;
					when x"05" => 	reg5_o   <= data;
					when x"06" => 	reg6_o   <= data;
					when x"07" => 	reg7_o   <= data;
					when x"08" => 	reg8_o   <= data;
					when x"09" => 	reg9_o   <= data;	
					when x"0A" => 	reg10_o   <= data;
					when x"0B" => 	reg11_o   <= data;
					when x"0C" => 	reg12_o   <= data;
					when x"0D" => 	reg13_o   <= data;
					when x"0E" => 	reg14_o   <= data;
					when x"0F" => 	reg15_o   <= data;
					when x"10" => 	reg16_o   <= data;
					when x"11" => 	reg17_o   <= data;
					when x"12" => 	reg18_o   <= data;
					when x"13" => 	reg19_o   <= data;
					when x"14" => 	reg20_o   <= data;
					when x"15" => 	reg21_o   <= data;
					when x"16" => 	reg22_o   <= data;
					when x"17" => 	reg23_o  <= data;
					when x"18" => 	reg24_o  <= data;
					when x"19" => 	reg25_o  <= data;
					when x"1A" => 	reg26_o  <= data;
					when x"1B" => 	reg27_o  <= data;
					when x"1C" => 	reg28_o  <= data;
					when x"1D" => 	reg29_o  <= data;
					when x"1E" => 	reg30_o  <= data;
					when x"1F" => 	reg31_o  <= data;				
					WHEN OTHERS =>  
				end case;  
			 end if;
	end if;
end process;
	

END behavior;
