library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
  port (
    clk     : in  std_logic;
    reset   : in  std_logic;
    req     : in  std_logic;
    N       : in  std_logic;
    Z       : in  std_logic;
    ack     : out std_logic;
    LDA     : out std_logic;
    LDB     : out std_logic;
    ABorALU : out std_logic;
    fn      : out std_logic_vector(1 downto 0)
  );
end entity fsm;

architecture rtl of fsm is

  type state_type is (
    op_a_await,
    op_a_release,
    op_b_await,
    calculate,
    subtract_b,
    result_release
  );

  signal state, next_state : state_type;

begin

  cl : process(all)
  begin
    -- Default values
    next_state <= state;

    ack     <= '0';
    LDA     <= '0';
    LDB     <= '0';
    ABorALU <= '0';             -- AB is selected by defaul
    fn      <= (others => '0'); -- A - B is selected by default

    -- State transition logic
    case (state) is
      when op_a_await =>
        if (req = '1') then
          LDA <= '1';
          next_state <= op_a_release;
        end if;

      when op_a_release =>
        ack <= '1';
        if (req = '0') then
          next_state <= op_b_await;
        end if;

      when op_b_await =>
        if (req = '1') then
          LDB <= '1';
          next_state <= calculate;
        end if;

      when calculate =>
        ABorALU <= '1';  -- ALU is selected
        fn      <= "00"; -- A - B is selected
        if (Z = '1') then
          -- A == B -> GCD found
          next_state <= result_release;
        elsif (N = '1') then
          -- A - B < 0 -> B > A
          next_state <= subtract_b;
        else
          -- A - B > 0 -> A > B
          LDA <= '1'; -- Load result into A
        end if;

      when subtract_b =>
        ABorALU <= '1';  -- ALU is selected
        fn      <= "01"; -- B - A is selected
        LDB     <= '1';  -- Load result into B

        next_state <= calculate;

      when result_release =>
        ack <= '1';
        if (req = '0') then
          next_state <= op_a_await;
        end if;

    end case;
  end process cl;

  seq : process(clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        state <= op_a_await;
      else
        state <= next_state;
      end if;
    end if;
  end process seq;

end architecture rtl;
