library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
  generic (
    n : integer := 20   -- filter of 2^n * 10ns = 10ms
	                      -- n should be set to 20 when synthesizing and 2 when simulating.
  );
	port ( clk : in std_logic;
		reset    : in  std_logic;
		sw       : in  std_logic;
		db_level : out std_logic;
		db_tick  : out std_logic);
end debounce;

architecture behavioral of debounce is
	type state_type is (zero, wait0, one, wait1);
	signal state_reg, state_next : state_type;
	signal q_reg, q_next         : unsigned(n-1 downto 0);
	signal q_load, q_dec, q_zero : std_logic;
	signal sw_reg1, sw_reg2      : std_logic;
begin

	process(clk, reset)
	begin
		if reset='1' then
			sw_reg2 <= '0';
			sw_reg1 <= '0';
		elsif rising_edge(clk) then
			sw_reg2 <= sw_reg1;
			sw_reg1 <= sw;
		end if;
	end process;

	-- fsmd state & data registers
	process(clk,reset)
	begin
		if reset='1' then
			state_reg <= zero;
			q_reg     <= (others => '0');
		elsif (rising_edge(clk)) then
			state_reg <= state_next;
			q_reg     <= q_next;
		end if;
	end process;

	-- fsmd data path (counter) next-state logic
	q_next <= (others => '1') when q_load='1' else
		q_reg - 1                when q_dec='1' else
		q_reg;
	q_zero <= '1' when q_next=0 else
		'0';

	-- fsmd control path next-state logic
	process(state_reg,sw_reg2,q_zero)
	begin
		q_load     <= '0';
		q_dec      <= '0';
		db_tick    <= '0';
		state_next <= state_reg;
		case state_reg is
			when zero =>
				db_level <= '0';
				if sw_reg2='1' then
					state_next <= wait1;
					q_load     <= '1';
				end if;
			when wait1 =>
				db_level <= '0';
				if sw_reg2='1' then
					q_dec <= '1';
					if q_zero='1' then
						state_next <= one;
						db_tick    <= '1';
					end if;
				else -- sw_reg2='0'
					state_next <= zero;
				end if;
			when one =>
				db_level <= '1';
				if sw_reg2='0' then
					state_next <= wait0;
					q_load     <= '1';
				end if;
			when wait0 =>
				db_level <= '1';
				if sw_reg2='0' then
					q_dec <= '1';
					if q_zero='1' then
						state_next <= zero;
					end if;
				else -- sw_reg2='1'
					state_next <= one;
				end if;
		end case;
	end process;

end behavioral;

