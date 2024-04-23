library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_lib.all;
use work.txt_lib.all;

entity vga is
	port (
		clk : in std_logic;
		rst : in std_logic;
		pause : in std_logic;
      button1 : in std_logic;
		button2 : in std_logic;
		left_paddle_up: in std_logic;
		left_paddle_down: in std_logic;
		right_paddle_up: in std_logic;
		right_paddle_down: in std_logic;
      red, green, blue : out std_logic_vector(3 downto 0);
      h_sync, v_sync : out std_logic;
      video_on : out std_logic
   );
end vga;

architecture BHV of vga is

	-- signals
   signal h_count, v_count : std_logic_vector(COUNT_RANGE);
   signal video_on_signal : std_logic;
	signal found_pixel : std_logic := '0';
	signal found_score_pixel : std_logic := '0';
	
	-- directions of ball
	signal move_left : std_logic := '0';
	signal move_right : std_logic := '1';
	signal move_up : std_logic := '0';
	signal move_down : std_logic := '1';
	
	-- ball
	signal x_start : integer := 290;
	signal x_end   : integer := 350;
	signal y_start : integer := 200;
	signal y_end   : integer := 280;
	
	-- paddles
	signal x_start_pl : integer := 20;
	signal x_end_pl   : integer := 60;
	signal y_start_pl : integer := 0;
	signal y_end_pl  : integer := 200;
	signal x_start_pr : integer := 580;
	signal x_end_pr   : integer := 620;
	signal y_start_pr : integer := 0;
	signal y_end_pr  : integer := 200;
	
	-- scores
	signal p1_score : integer := 0;
	signal p2_score : integer := 0;
	
	-- new clock and states
	signal new_clk : std_logic;
	type State_Type is (start_screen, gameplay, end_screen_p1, end_screen_p2);
   signal curr_state : State_Type := start_screen;

begin
	-- sync declaration
   vga_sync_gen_inst : entity work.vga_sync_gen
   port map (
      clk => clk,
      rst => rst,
      h_count_r => h_count,
      v_count_r => v_count,
      h_sync => h_sync,
      v_sync => v_sync,
      video_on => video_on_signal
   );
	clock_div_inst : entity work.clk_div
		generic map (
				clk_in_freq  => 50000000,
				clk_out_freq => 300)
		port map (
				clk_in  => clk,
				clk_out => new_clk,
				rst     => rst
		);
		
	-- process to move between states based on buttons or score
	process (new_clk, button1, button2) 
	begin
		 if rising_edge(new_clk) then
			 case curr_state is
				when start_screen =>
				
					-- switch to gameplay if button is pressed
					if button1 = '1' then
						curr_state <= gameplay;
					end if;
				
				when gameplay =>
				
					-- switch to end screen depending on score
					if p1_score = 10 then
						curr_state <= end_screen_p1;
					end if;
					if p2_score = 10 then
						curr_state <= end_screen_p2;
					end if;
				
				when end_screen_p1 =>
				
					-- switch to start screen when button is pressed
					if button2 = '1' then
						curr_state <= start_screen;
					end if;
				
				when end_screen_p2 =>
					
					-- switch to start screen when button is pressed
					if button2 = '1' then
						curr_state <= start_screen;
					end if;
				
			 end case;
		 end if;
	end process;
	
	-- process to move the box around
	process (new_clk, rst)
	begin
		if curr_state = gameplay then
			if rst = '1' then 
				
				-- reset starting location values
				x_start <= 290;
				x_end <= 350;
				y_start <= 200;
				y_end <= 280;
				
			elsif pause = '1' then
			
				-- box doesn't move while it is paused
				
			elsif rising_edge(new_clk) then
				-- move box
				
				-- adjust x value
				if move_right = '1' then
					-- move right
					x_start <= x_start + 1;
					x_end <= x_end + 1;
					
					-- check for collision or score
					if (x_end = x_start_pr) and 
					not(y_start > y_end_pr or y_end < y_start_pr) then
						
						-- switch direction 
						move_right <= '0';
						move_left <= '1';
						
					elsif x_end = H_DISPLAY_END then
						-- increase score
						p1_score <= p1_score + 1;
						
						-- reset values
						x_start <= 290;
						x_end <= 350;
						y_start <= 200;
						y_end <= 280;
						
						-- switch direction 
						move_right <= '0';
						move_left <= '1';
					end if;
					
				elsif move_left = '1' then
					-- move left
					x_start <= x_start - 1;
					x_end <= x_end - 1;
					
					-- check for collision or score
					if (x_start = x_end_pl) and 
					not(y_start > y_end_pl or y_end < y_start_pl) then
						
						-- switch direction 
						move_right <= '1';
						move_left <= '0';
						
					elsif x_start = 0 then
						-- increase score
						p2_score <= p2_score + 1;
						
						-- reset values
						x_start <= 290;
						x_end <= 350;
						y_start <= 200;
						y_end <= 280;
						
						-- switch direction 
						move_right <= '1';
						move_left <= '0';
					end if;
					
				end if;
				
				-- adjust y value
				if move_down = '1' then
					-- move down
					y_start <= y_start + 1;
					y_end <= y_end + 1;
					
					-- reverse direction if at the edge of the screen
					if y_end = V_DISPLAY_END then
						move_down <= '0';
						move_up <= '1';
					end if;
					
				elsif move_up = '1' then
					-- move up
					y_start <= y_start - 1;
					y_end <= y_end - 1;
					
					-- reverse direction if at the edge of the screen
					if y_start = 0 then
						move_down <= '1';
						move_up <= '0';
					end if;
					
				end if;
				
			end if;
		elsif curr_state = start_screen then
			-- clamp scores to 0 on the start screen
			if p1_score > 0 or p2_score > 0 then
				p1_score <= 0;
				p2_score <= 0;
			end if;
		end if;
	end process; 
	
	
	-- process to move the left paddle
	process (new_clk)
	begin
		if curr_state = gameplay then
			if rising_edge(new_clk) then
			
				if (left_paddle_down = '1') and (y_end_pl < V_DISPLAY_END) then
					y_start_pl <= y_start_pl + 2;
					y_end_pl <= y_end_pl + 2;
				end if;
				
				if (left_paddle_up = '1') and (y_start_pl > 0) then
					y_start_pl <= y_start_pl - 2;
					y_end_pl <= y_end_pl - 2;
				end if;
			
			end if;
		end if;
	end process;
	
	-- process to move the right paddle
	process (new_clk)
	begin
		if curr_state = gameplay then
			if rising_edge(new_clk) then
			
				if (right_paddle_down = '1') and (y_end_pr < V_DISPLAY_END) then
					y_start_pr <= y_start_pr + 2;
					y_end_pr <= y_end_pr + 2;
				end if;
				
				if (right_paddle_up = '1') and (y_start_pr > 0) then
					y_start_pr <= y_start_pr - 2;
					y_end_pr <= y_end_pr - 2;
				end if;
			
			end if;
		end if;
	end process;
	
	
	-- for v count and h count
   process (h_count, v_count, video_on_signal, new_clk)
   begin
	
		if curr_state = gameplay then
		
			found_score_pixel <= '0';
		
			if (p1_score = 1) then
			
				-- check pixels for score
				for i in p1_1'range loop
					if ((to_integer(unsigned(h_count)) = p1_1(i).x) and (to_integer(unsigned(v_count)) = p1_1(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p1_score = 2) then
			
				-- check pixels for score
				for i in p1_2'range loop
					if ((to_integer(unsigned(h_count)) = p1_2(i).x) and (to_integer(unsigned(v_count)) = p1_2(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p1_score = 3) then
			
				-- check pixels for score
				for i in p1_3'range loop
					if ((to_integer(unsigned(h_count)) = p1_3(i).x) and (to_integer(unsigned(v_count)) = p1_3(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p1_score = 4) then
			
				-- check pixels for score
				for i in p1_4'range loop
					if ((to_integer(unsigned(h_count)) = p1_4(i).x) and (to_integer(unsigned(v_count)) = p1_4(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p1_score = 5) then
			
				-- check pixels for score
				for i in p1_5'range loop
					if ((to_integer(unsigned(h_count)) = p1_5(i).x) and (to_integer(unsigned(v_count)) = p1_5(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p1_score = 6) then
			
				-- check pixels for score
				for i in p1_6'range loop
					if ((to_integer(unsigned(h_count)) = p1_6(i).x) and (to_integer(unsigned(v_count)) = p1_6(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p1_score = 7) then
			
				-- check pixels for score
				for i in p1_7'range loop
					if ((to_integer(unsigned(h_count)) = p1_7(i).x) and (to_integer(unsigned(v_count)) = p1_7(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p1_score = 8) then
			
				-- check pixels for score
				for i in p1_8'range loop
					if ((to_integer(unsigned(h_count)) = p1_8(i).x) and (to_integer(unsigned(v_count)) = p1_8(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p1_score = 9) then
			
				-- check pixels for score
				for i in p1_9'range loop
					if ((to_integer(unsigned(h_count)) = p1_9(i).x) and (to_integer(unsigned(v_count)) = p1_9(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			end if;
			
			if (p2_score = 1) then
			
				-- check pixels for score
				for i in p2_1'range loop
					if ((to_integer(unsigned(h_count)) = p2_1(i).x) and (to_integer(unsigned(v_count)) = p2_1(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p2_score = 2) then
			
				-- check pixels for score
				for i in p2_2'range loop
					if ((to_integer(unsigned(h_count)) = p2_2(i).x) and (to_integer(unsigned(v_count)) = p2_2(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p2_score = 3) then
			
				-- check pixels for score
				for i in p2_3'range loop
					if ((to_integer(unsigned(h_count)) = p2_3(i).x) and (to_integer(unsigned(v_count)) = p2_3(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p2_score = 4) then
			
				-- check pixels for score
				for i in p2_4'range loop
					if ((to_integer(unsigned(h_count)) = p2_4(i).x) and (to_integer(unsigned(v_count)) = p2_4(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p2_score = 5) then
			
				-- check pixels for score
				for i in p2_5'range loop
					if ((to_integer(unsigned(h_count)) = p2_5(i).x) and (to_integer(unsigned(v_count)) = p2_5(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p2_score = 6) then
			
				-- check pixels for score
				for i in p2_6'range loop
					if ((to_integer(unsigned(h_count)) = p2_6(i).x) and (to_integer(unsigned(v_count)) = p2_6(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
				
			elsif (p2_score = 7) then
				
				-- check pixels for score
				for i in p2_7'range loop
					if ((to_integer(unsigned(h_count)) = p2_7(i).x) and (to_integer(unsigned(v_count)) = p2_7(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p2_score = 8) then
			
				-- check pixels for score
				for i in p2_8'range loop
					if ((to_integer(unsigned(h_count)) = p2_8(i).x) and (to_integer(unsigned(v_count)) = p2_8(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			elsif (p2_score = 9) then
			
				-- check pixels for score
				for i in p2_9'range loop
					if ((to_integer(unsigned(h_count)) = p2_9(i).x) and (to_integer(unsigned(v_count)) = p2_9(i).y)) then
						found_score_pixel <= '1';
					end if;
				end loop;
			
			end if;
			
			
			-- check if within the bounds
			if ((to_integer(unsigned(v_count)) >= y_start) and 
			(to_integer(unsigned(v_count)) <= y_end) and
			(to_integer(unsigned(h_count)) >= x_start) and 
			(to_integer(unsigned(h_count)) <= x_end)) or
			((to_integer(unsigned(v_count)) >= y_start_pl) and 
			(to_integer(unsigned(v_count)) <= y_end_pl) and
			(to_integer(unsigned(h_count)) >= x_start_pl) and 
			(to_integer(unsigned(h_count)) <= x_end_pl)) or
			((to_integer(unsigned(v_count)) >= y_start_pr) and 
			(to_integer(unsigned(v_count)) <= y_end_pr) and
			(to_integer(unsigned(h_count)) >= x_start_pr) and 
			(to_integer(unsigned(h_count)) <= x_end_pr)) or
			(found_score_pixel = '1')
			then

				-- if it is within bounds for either paddle or the ball
				if video_on_signal = '1' then
					red <= "0111";
					green <= "0011";
					blue <= "1011";
				end if;
					
		   else
		  
				-- if not within bounds then no color
				red <= (others => '0');
				green <= (others => '0');
				blue <= (others => '0');			
				
		   end if;
		elsif curr_state = start_screen then
		
			found_pixel <= '0';
			
			-- see if current x and y coords should be drawn
			for i in start_screen_arr'range loop
				if ((to_integer(unsigned(h_count)) = start_screen_arr(i).x) and (to_integer(unsigned(v_count)) = start_screen_arr(i).y)) then
					found_pixel <= '1';
				end if;
			end loop;
			
			-- if they should be drawn then draw as white, else no color
			if found_pixel = '1' and video_on_signal = '1' then
				red <= "1111";
				green <= "1111";
				blue <= "1111";
			else
				red <= (others => '0');
				green <= (others => '0');
				blue <= (others => '0');
			end if;
			
		elsif curr_state = end_screen_p1 then
				
			found_pixel <= '0';
			
			-- see if current x and y coords should be drawn
			for i in p1_end_screen'range loop
				if ((to_integer(unsigned(h_count)) = p1_end_screen(i).x) and (to_integer(unsigned(v_count)) = p1_end_screen(i).y)) then
					found_pixel <= '1';
				end if;
			end loop;
			
			-- if they should be drawn then draw as white, else no color
			if found_pixel = '1' and video_on_signal = '1' then
				red <= "1111";
				green <= "1111";
				blue <= "1111";
			else
				red <= (others => '0');
				green <= (others => '0');
				blue <= (others => '0');
			end if;
		
		elsif curr_state = end_screen_p2 then
		
			found_pixel <= '0';
			
			for i in p2_end_screen'range loop
				if ((to_integer(unsigned(h_count)) = p2_end_screen(i).x) and (to_integer(unsigned(v_count)) = p2_end_screen(i).y)) then
					found_pixel <= '1';
				end if;
			end loop;
			
			if found_pixel = '1' and video_on_signal = '1' then
				red <= "1111";
				green <= "1111";
				blue <= "1111";
			else
				red <= (others => '0');
				green <= (others => '0');
				blue <= (others => '0');
			end if;
		
		end if;
	
	end process;

   -- output the video_on signal
	video_on <= video_on_signal;

end BHV;
