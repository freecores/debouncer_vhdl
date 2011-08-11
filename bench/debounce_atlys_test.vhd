-- TestBench Template 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
end testbench;

architecture behavior of testbench is 

    --=============================================================================================
    -- Constants
    --=============================================================================================
    -- clock period
    constant CLK_PERIOD : time := 10 ns;

    --=============================================================================================
    -- COMPONENT DECLARATIONS
    --=============================================================================================
    COMPONENT debounce_atlys_top
    PORT(
        gclk_i : IN std_logic;
        sw_i : IN std_logic_vector(7 downto 0);          
        led_o : OUT std_logic_vector(7 downto 0);
        strb_o : OUT std_logic;
        dbg_o : OUT std_logic_vector(15 downto 0)
    );
    END COMPONENT;

    --=============================================================================================
    -- Signals for internal operation
    --=============================================================================================
    --- clock signals ---
    signal sysclk           : std_logic := '0';                                 -- 100MHz clock
    --- switch debouncer signals ---
    signal sw_data          : std_logic_vector (7 downto 0) := (others => '0'); -- switch data
    -- debug output signals
    signal leds             : std_logic_vector (7 downto 0);    -- board leds
    signal dbg              : std_logic_vector (15 downto 0);   -- LA debug vector
    signal strobe           : std_logic;
    signal sw_input         : std_logic_vector (7 downto 0);    -- raw switches
    signal sw_output        : std_logic_vector (7 downto 0);    -- debounced switches
begin

    --=============================================================================================
    -- COMPONENT INSTANTIATIONS FOR THE CORES UNDER TEST
    --=============================================================================================
    -- debounce_atlys_top:
    --      receives the 100 MHz clock from the board clock oscillator
    --      receives the 8 slide switches and 5 pushbuttons as test stimuli
    --      connects to 8 board LEDs
    --      connects to 16 debug pins
    Inst_debounce_atlys_top: debounce_atlys_top 
    PORT MAP(
        gclk_i => sysclk,       -- connect board clock
        sw_i => sw_data,        -- connect board switches
        led_o => leds,          -- connect board leds
        strb_o => strobe,       -- connect strobe debug
        dbg_o => dbg            -- connect logic analyzer
    );

    -- debug signals mapped on dbg vector
    sw_input   <= dbg(7 downto 0);
    sw_output    <= dbg(15 downto 8);

    --=============================================================================================
    -- CLOCK GENERATION
    --=============================================================================================
    gclk_proc: process is
    begin
        loop
            sysclk <= not sysclk;
            wait for CLK_PERIOD / 2;
        end loop;
    end process gclk_proc;

    --=============================================================================================
    -- TEST BENCH STIMULI
    --=============================================================================================
    tb : process
    begin
        wait for 100 ns; -- wait until global set/reset completes
        sw_data <= X"00";
        wait for 1 us;
        
        -- change switches to 0x93, with bouncing
        sw_data <= X"81";
        wait for 50 ns;
        sw_data <= X"80";
        wait for 250 ns;
        sw_data <= X"91";
        wait for 40 ns;
        sw_data <= X"81";
        wait for 90 ns;
        sw_data <= X"93";
        wait for 40 us;
        
        -- change switches to 0x3E, with bouncing
        sw_data <= X"97";
        wait for 50 ns;
        sw_data <= X"16";
        wait for 150 ns;
        sw_data <= X"3E";
        wait for 300 ns;
        sw_data <= X"2C";
        wait for 50 ns;
        sw_data <= X"3D";
        wait for 400 ns;
        sw_data <= X"3E";
        wait for 50 us;
        
        -- end simulation
        assert false report "End Simulation" severity failure; -- stop simulation
    end process tb;
    --  End Test Bench 
END;
