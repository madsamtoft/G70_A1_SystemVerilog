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
    op_a_await,    -- Await and read first operand into reg_a
    op_a_release,  -- Reset operand exchange handshake
    op_b_await,    -- Await and read second operand into reg_b
    calculate,     -- calculateulate GCD of reg_a and reg_b
    result_release -- Await acknowledgement of result and reset component
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
    C <= (others => '0');

    case state is
        when op_a_await =>
          if req = '1' and ab /= (ab'range => '0') then
            next_reg_a <= ab;
            next_state <= op_a_release;
          end if;

        when op_a_release =>
          ack <= '1';
          if req = '0' then
            next_state <= op_b_await;
          end if;

        when op_b_await =>
          if req = '1' and ab /= (ab'range => '0') then
            next_reg_b <= ab;
            next_state <= calculate;
          end if;

        when calculate =>
          if reg_a > reg_b then
            next_reg_a <= reg_a - reg_b;
          elsif reg_a < reg_b then
            next_reg_b <= reg_b - reg_a;
          else
            next_state <= result_release;
          end if;

        when result_release =>
          ack <= '1';
          C <= reg_a;
          if req = '0' then
            next_state <= op_a_await;
          end if;
    end case;
  end process cl;


  -- State and datapath registers
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

end fsmd;
