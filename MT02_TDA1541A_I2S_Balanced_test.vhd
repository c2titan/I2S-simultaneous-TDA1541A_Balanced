----------------------------------------------------------------------------------------
-- VHDL code for converting standard I2S signal (64fs) to offset-binary (simultaneous)
-- ("I2S 2x32=64-bit = 64fs" to "16-bit offset-binary" with inverted MSB and 
-- stop-clocked BCK) for TDA1541A DAC (stereo) without the use of MCLK.
-- Basic data synchronisation is incorporated on LRCK signal and 
-- the sound is nice, clean, without digital interference.
-- Balanced mode
-- The code is very simple, without advanced techniques, based mostly on standard logic.
-- Therefore inexperienced users can understand and modify it for other similar DACs.
-- It has low load on the CPLD and it takes up little memory.

-- Only 3 signal wires (I2S) are needed for input (DATA, BCK, LRCK).
-- Output is offset-binary specified for TDA1541A with balanced possibility: 
--  CL  (outCL)  - stopped DAC clock
--  DL  (outDL)  - Left DAC data (inversed MSB)
--  DLi (outDLi) - Left DAC data inverted (inversed MSB)
--  LL  (outLL)  - Latch for left channels (latched together)
--  DR  (outDR)  - Right DAC data (inversed MSB)
--  DRi (outDRi) - Right DAC data inverted (inversed MSB)
--  LR  (outLR)  - Latch for right channels (latched together)

-- It flawlessly works with the cheap CPLD EPM240T100C5 from aliexpress.

-- This VHDL code is open and free for all.

-- If you like my work and find it helpful, you can donate coffee for me :D 
-- https://www.buymeacoffee.com/miro1360coffee  Thank you :)
-- by miro1360, 10/2024
----------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity MT02_TDA1541A_I2S_Balanced is
	port(
		inBCK   : in  std_logic;
		inDATA  : in  std_logic;
		inLRCK  : in  std_logic;
		outCL   : out std_logic := '0';
		outDL   : out std_logic := '0';
		outDLi  : out std_logic := '0';
		outLL   : out std_logic := '0';
		outCR   : out std_logic := '0';
		outDR   : out std_logic := '0';
		outDRi  : out std_logic := '0';
		outLR   : out std_logic := '0'
	);
end MT02_TDA1541A_I2S_Balanced;


architecture I2S_OB_TDA1541A_Balanced of MT02_TDA1541A_I2S_Balanced is
	signal cntOB      : integer range 0 to 32 := 0;
	signal synchLRCK  : std_logic := '0';
	signal resetCLK   : std_logic := '0';
	signal dataFlagL  : std_logic := '0';
	signal dataFlagR  : std_logic := '0';
	signal leFlag     : std_logic := '0';
	signal lrckFlag0  : std_logic := '0';
	signal lrckFlag1  : std_logic := '0';
	signal srDATA     : std_logic_vector(3 - 2 downto 0); -- shift register buffer
	signal sdDATA     : std_logic;                        -- delayed data from register
	signal srDATA_L   : std_logic_vector(33 downto 0);    -- shift register buffer for left data (width = 32 + srDATA)
	signal sdDATA_L   : std_logic;                        -- delayed left data from register
begin

	
	synch_counter_OB_on_inLRCK : process(inBCK, inLRCK, synchLRCK, resetCLK)
	begin
		
		if rising_edge(inBCK) then
			
			lrckFlag1 <= lrckFlag0;
			lrckFlag0 <= inLRCK;
			-- detect LRCK event
			if	(lrckFlag1 = '1') AND (lrckFlag0 = '0') then
				synchLRCK <= '1';
			elsif (lrckFlag1 = '0') AND (lrckFlag0 = '1') then
				synchLRCK <= '1';
			else
				synchLRCK <= '0';
			end if;

		end if;
		
		if synchLRCK = '1' then	-- if LRCK event detected, reset counter_OB
			resetCLK <= '1';
		else
			resetCLK <= '0';
		end if;
		
	end process;
	
	
	counter_OB : process(inBCK)
	begin
		if rising_edge(inBCK) then
			if resetCLK = '1' then	-- synchronize/reset counter on each LRCK event
				cntOB <= 0;
			elsif cntOB < 31 then
				cntOB <= cntOB + 1;
			else
				cntOB <= 0;
			end if;
		end if;
	end process;
	
	
	delay_data : process(inBCK)	-- delay data for proper alignment
	begin
		if rising_edge(inBCK) then
			srDATA <= srDATA(srDATA'high - 1 downto srDATA'low) & inDATA;
			sdDATA <= srDATA(srDATA'high);
		end if;
	end process;

	
	delay_data_L : process(inBCK)	-- delay left data for proper alignment
	begin
		if rising_edge(inBCK) then
			srDATA_L <= srDATA_L(srDATA_L'high - 1 downto srDATA_L'low) & inDATA;
			sdDATA_L <= srDATA_L(srDATA_L'high);
		end if;
	end process;
	
	
	output_OB : process(inBCK, cntOB, inLRCK)
	begin
	
		if falling_edge(inBCK) then
			
			if (cntOB = 1) AND (inLRCK = '1') then
				dataFlagR <= NOT sdDATA;	-- invert only MSB
				dataFlagL <= NOT sdDATA_L;	-- invert only MSB
			elsif (cntOB >= 2) AND (cntOB < 17) AND (inLRCK = '1') then
				dataFlagR <= sdDATA; -- rest 15-bit data are not inverted
				dataFlagL <= sdDATA_L;	-- rest 15-bit data are not inverted
			else
				dataFlagR <= '0';
				dataFlagL <= '0';
			end if;
			
			if (cntOB = 17) AND (inLRCK = '0') then	-- LE pulse duration (4 BCK)
				leFlag <= '1';
			elsif (cntOB >= 21) then
				leFlag <= '0';
			end if;
			
			outDL  <= dataFlagL;
			outDLi <= NOT dataFlagL;
			outDR  <= dataFlagR;
			outDRi <= NOT dataFlagL;
			
		end if;
		
		if rising_edge(inBCK) then
			outLL <= leFlag;	-- Latch pulse on rising BCK
			outLR <= leFlag;	-- Latch pulse on rising BCK
		end if;
		
		if (cntOB >= 2) AND (cntOB < 18) AND (inLRCK = '1') then
			outCL <= NOT inBCK;	-- stopped clock for left channels
			outCR <= NOT inBCK;	-- stopped clock for right channels
		else
			outCL <= '0';
			outCR <= '0';
		end if;
		
	end process;
	
end I2S_OB_TDA1541A_Balanced;