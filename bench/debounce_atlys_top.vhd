----------------------------------------------------------------------------------
-- Author:          Jonny Doin, jdoin@opencores.org, jonnydoin@gmail.com
-- 
-- Create Date:     01:21:32 06/30/2011 
-- Design Name: 
-- Module Name:     debounce_atlys_top
-- Project Name:    spi_master_slave
-- Target Devices:  Spartan-6 LX45
-- Tool versions:   ISE 13.1
-- Description: 
--          This is a verification project for the Digilent Atlys board, to test the SPI_MASTER, SPI_SLAVE and GRP_DEBOUNCE cores.
--          It uses the board's 100MHz clock input, and clocks all sequential logic at this clock.
--
--          See the "spi_master_atlys.ucf" file for pin assignments.
--          The test circuit uses the VHDCI connector on the Atlys to implement a 16-pin debug port to be used
--          with a Tektronix MSO2014. The 16 debug pins are brought to 2 8x2 headers that form a umbilical
--          digital pod port.
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2011/07/02   v0.01.0010  [JD]    implemented a wire-through from switches to LEDs, just to test the toolchain. It worked!
-- 2011/07/03   v0.01.0020  [JD]    added clock input, and a simple LED blinker for each LED. 
-- 2011/07/03   v0.01.0030  [JD]    added clear input, and instantiated a SPI_MASTER from my OpenCores project. 
-- 2011/07/04   v0.01.0040  [JD]    changed all clocks to clock enables, and use the 100MHz board gclk_i to clock all registers.
--                                  this change made the design go up to 288MHz, after synthesis.
-- 2011/07/07   v0.03.0050  [JD]    implemented a 16pin umbilical port for the MSO2014 in the Atlys VmodBB board, and moved all
--                                  external monitoring pins to the VHDCI ports.
-- 2011/07/10   v1.10.0075  [JD]    verified spi_master_slave at 50MHz, 25MHz, 16.666MHz, 12.5MHz, 10MHz, 8.333MHz, 7.1428MHz, 
--                                  6.25MHz, 1MHz and 500kHz 
-- 2011/07/29   v1.12.0105  [JD]    spi_master.vhd and spi_slave_vhd changed to fix CPHA='1' bug.
-- 2011/08/02   v1.13.0110  [JD]    testbed for continuous transfer in FPGA hardware.
--
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity debounce_atlys_top is
    Port (
        gclk_i : in std_logic := 'X';                           -- board clock input 100MHz
        --- input slide switches ---            
        sw_i : in std_logic_vector (7 downto 0);                -- 8 input slide switches
        --- output LEDs ----            
        led_o : out std_logic_vector (7 downto 0);              -- output leds
        --- debug outputs ---
        strb_o : out std_logic;                                 -- core strobe output
        dbg_o : out std_logic_vector (15 downto 0)              -- 16 generic debug pins
    );                      
end debounce_atlys_top;

architecture rtl of debounce_atlys_top is

    --=============================================================================================
    -- Constants
    --=============================================================================================
    -- debounce generics
    constant N          : integer   := 8;           -- 8 bits (8 switch inputs)
    constant CNT_VAL    : integer   := 1000;        -- debounce period = 1000 * 10 ns (10 us)
    
    --=============================================================================================
    -- Signals for internal operation
    --=============================================================================================
    --- switch debouncer signals ---
    signal sw_data          : std_logic_vector (7 downto 0) := (others => '0'); -- debounced switch data
    signal sw_reg           : std_logic_vector (7 downto 0) := (others => '0'); -- registered switch data 
    signal sw_new           : std_logic := '0';
    -- debug output signals
    signal leds_reg         : std_logic_vector (7 downto 0) := (others => '0');
    signal dbg              : std_logic_vector (15 downto 0) := (others => '0');
begin

    --=============================================================================================
    -- COMPONENT INSTANTIATIONS FOR THE CORES UNDER TEST
    --=============================================================================================
    -- debounce for the input switches, with new data strobe output
    Inst_sw_debouncer: entity work.grp_debouncer(rtl)
        generic map (N => N, CNT_VAL => CNT_VAL)
        port map(  
            clk_i => gclk_i,                    -- system clock
            data_i => sw_i,                     -- noisy input data
            data_o => sw_data,                  -- registered stable output data
            strb_o => sw_new                    -- transition detection
        );

    --=============================================================================================
    --  REGISTER TRANSFER PROCESSES
    --=============================================================================================
    -- data registers: synchronous to the system clock
    dat_reg_proc : process (gclk_i) is
    begin
        -- transfer switch data when new switch is detected
        if gclk_i'event and gclk_i = '1' then
            if sw_new = '1' then                -- clock enable
                sw_reg <= sw_data;              -- only provide local reset for the state registers
            end if;
        end if;
    end process dat_reg_proc;

    --=============================================================================================
    --  COMBINATORIAL LOGIC PROCESSES
    --=============================================================================================
    -- LED register update
    leds_reg_proc: leds_reg <= sw_reg;          -- leds register is a copy of the updated switch register

    -- update debug register
    dbg_lo_proc: dbg(7 downto 0) <= sw_i;       -- lower debug port has debounced switch data
    dbg_hi_proc: dbg(15 downto 8) <= sw_data;   -- upper debug port has direct switch connections
    

    --=============================================================================================
    --  OUTPUT LOGIC PROCESSES
    --=============================================================================================
    -- connect leds_reg signal to LED outputs
    led_o_proc: led_o <= leds_reg;              -- drive the output leds

    --=============================================================================================
    --  DEBUG LOGIC PROCESSES
    --=============================================================================================
    -- connect the debug vector outputs
    strb_o_proc: strb_o <= sw_new;              -- connect strobe debug out
    dbg_o_proc: dbg_o <= dbg;                   -- drive the logic analyzer port
    
end rtl;

