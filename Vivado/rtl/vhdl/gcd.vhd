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
  port (clk : in std_logic;             -- The clock signal.
    reset : in  std_logic;              -- Reset the module.
    req   : in  std_logic;              -- Input operand / start computation.
    AB    : in  unsigned(15 downto 0);  -- The two operands.
    ack   : out std_logic;              -- Computation is complete.
    C     : out unsigned(15 downto 0)); -- The result.
end gcd;

architecture fsmd of gcd is

  type state_type is (
    op1_await,  -- Await and read first operand into reg_a
    hs_reset,   -- Reset operand exchange handshake
    op2_await,  -- Await and read second operand into reg_b
    calc,       -- Calculate GCD of reg_a and reg_b
    read_await  -- Await acknowledgement of result and reset component
  );

  signal reg_a, next_reg_a, next_reg_b, reg_b : unsigned(15 downto 0);

  signal state, next_state : state_type;


begin

  -- Combinational next-state and datapath logic
  cl : process(all)
  begin
    next_reg_a <= reg_a;
    next_reg_b <= reg_b;
    next_state <= state;

    ack <= '0';
    C <= '0';

    case state is
        when op1_await =>
          if req = '1' and ab /= (ab'range => '0') then
            next_reg_a <= ab;
            next_state <= hs_reset;
          end if;

        when hs_reset =>
          ack <= '1';
          if req = '0' then
            next_state <= op2_await;
          end if;

        when op2_await =>
          if req = '1' and ab /= (ab'range => '0') then
            next_reg_b <= ab;
            next_state <= calc;
          end if;

        when calc =>
          if reg_a > reg_b then
            next_reg_a <= reg_a - reg_b;

          elsif reg_a < reg_b then
            next_reg_b <= reg_b - reg_a;

          else
            next_state <= read_await;
          end if;

        when read_await =>
          ack <= '1';
          C <= reg_a;
          if req = '0' then
            next_state <= op1_await;
          end if;
    end case;
  end process cl;


  -- State and datapath registers
  seq : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= op1_await;
        reg_a <= (others => '0');
        reg_b <= (others => '0');
      else
        state <= next_state;
        reg_a <= next_reg_a;
        reg_b <= next_reg_b;
      end if;
    end if;
  end process seq;

end fsmd;
