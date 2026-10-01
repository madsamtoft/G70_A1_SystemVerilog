-- -----------------------------------------------------------------------------
--
--  Title      :  FSMD implementation of GCD
--             :
--  Developers :  Jens Sparsø, Rasmus Bo Sørensen and Mathias Møller Bruhn
--           :
--  Purpose    :  This is a FSMD (finite state machine with datapath) 
--             :  implementation the GCD circuit
--             :
--  Revision   :  02203 fall 2019 v.5.0
--
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gcd is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    req   : in  std_logic;
    AB    : in  unsigned(15 downto 0);
    ack   : out std_logic;
    C     : out unsigned(15 downto 0)
  );
end entity gcd;

architecture fsmd of gcd is

  type state_type is (
    op_a_await,
    op_a_release,
    op_b_await,
    calculate,
    subtract_b,
    result_release
  );

  signal state, next_state : state_type;

  signal reg_a, next_reg_a : unsigned(15 downto 0);
  signal reg_b, next_reg_b : unsigned(15 downto 0);

begin

  cl : process(all)
    variable sub_left, sub_right : unsigned(15 downto 0);
    variable difference          : unsigned(15 downto 0);
    variable borrow              : std_logic;
  begin
    next_state <= state;
    next_reg_a <= reg_a;
    next_reg_b <= reg_b;

    ack <= '0';
    C   <= reg_a;

    -- Select the order of the subtraction
    sub_left  := reg_a;
    sub_right := reg_b;

    if state = subtract_b then
      sub_left  := reg_b;
      sub_right := reg_a;
    end if;

    difference := sub_left - sub_right;

    -- Determine unsigned borrow using MSBs
    if (sub_left(15) xor sub_right(15)) = '1' then
      borrow := sub_right(15);
    else
      borrow := difference(15);
    end if;

    case state is
      when op_a_await =>
        if req = '1' then
          next_reg_a <= AB;
          next_state <= op_a_release;
        end if;

      when op_a_release =>
        ack <= '1';
        if req = '0' then
          next_state <= op_b_await;
        end if;

      when op_b_await =>
        if req = '1' then
          next_reg_b <= AB;
          next_state <= calculate;
        end if;

      when calculate =>
        if difference = 0 then
          next_state <= result_release;
        elsif borrow = '1' then
          next_state <= subtract_b;
        else
          next_reg_a <= difference;
        end if;

      when subtract_b =>
        next_reg_b <= difference;
        next_state <= calculate;

      when result_release =>
        ack <= '1';
        if req = '0' then
          next_state <= op_a_await;
        end if;

      when others =>
        next_state <= op_a_await;
    end case;
  end process cl;

  seq : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= op_a_await;
        reg_a <= (others => '0');
        reg_b <= (others => '0');
      else
        state <= next_state;
        reg_a <= next_reg_a;
        reg_b <= next_reg_b;
      end if;
    end if;
  end process seq;

end architecture fsmd;