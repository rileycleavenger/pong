library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_lib.all;

entity vga_sync_gen is
    port (
        clk : in std_logic;
        rst : in std_logic;
        h_count_r, v_count_r : out std_logic_vector(COUNT_RANGE);
        h_sync, v_sync, video_on : out std_logic
    );
end vga_sync_gen;

architecture BHV of vga_sync_gen is
	
	-- declare two counters
	signal h_count : unsigned(COUNT_RANGE) := (others => '0');
	signal v_count : unsigned(COUNT_RANGE) := (others => '0');

begin
	
	-- assign entity vectors to vectors of same range as counters
	h_count_r <= std_logic_vector(h_count);
	v_count_r <= std_logic_vector(v_count);
	
	process(clk, rst)
	begin
		if(rst = '1') then
			-- reset both counters
			h_count <= (others => '0');
			v_count <= (others => '0');
		elsif(rising_edge(clk)) then
		
			-- increment horizontal count
			h_count <= h_count + 1;
			
			-- restart horizontal count if its at the end of the screen 
			if(h_count = H_MAX) then
				h_count <= (others => '0');
			end if;
			
			-- increment vertical count if horizontal count reaches end of screen
			if(h_count = H_VERT_INC) then
				v_count <= v_count + 1;
			end if;
			
			-- restart vertical count if its at the end of the screen 
			if(v_count = V_MAX) then
				v_count <= (others => '0');
			end if;
			
		end if;
	end process;
	
	process(h_count, v_count)
	begin
		
		-- check if horizontal count is in the hsync range
		if((to_integer(h_count) >= HSYNC_BEGIN) and (to_integer(h_count) <= HSYNC_END)) then
			h_sync <= '0';
		else
			h_sync <= '1';
		end if;
		
		-- check if vertical count is in the vsync range
		if((to_integer(v_count) >= VSYNC_BEGIN) and (to_integer(v_count) <= VSYNC_END)) then
			v_sync <= '0';
		else
			v_sync <= '1';
		end if;
		
		-- make sure both counts are within display range, and if so then video_on = high
		if((to_integer(h_count) <= H_DISPLAY_END) and (to_integer(v_count) <= V_DISPLAY_END)) then
			video_on <= '1';
		else
			video_on <= '0';
		end if;
		
	end process;
	
end BHV;
