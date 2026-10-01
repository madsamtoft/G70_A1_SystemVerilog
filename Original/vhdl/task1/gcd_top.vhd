-- -----------------------------------------------------------------------------
--
--  Title      :  Specification of GCD entity
--             :
--  Developers :  Jens Sparsø, Rasmus Bo Sørensen and Mathias Møller Bruhn
--             :
--  Purpose    : Specification of gcd_top 
--             :
--  Revision   :  02203 fall 2022 v.7.0
--
--------------------------------------------------------------------------------
-- The GCD-module computes the greatest common divisor of two integers
-- The module behaves as an SLT-module with handshake signals "req" and "ack".
-- "req" and "ack" follow a 4-phase fully interlocked handshake protocol.
--
-- A computation involves two handshakes.
--   (1) During the first handshake the operand A is input.
--   (2) During the second the B operand is input, the computation is performed and
--       the result C is output.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity gcd_top is
generic (
      n : integer -- not used in task 1
    );
	port (clk : in std_logic; -- The clock signal.
		reset : in std_logic;   -- Reset the module.
		req   : in std_logic;   -- Input operand / Start computation..
		AB    : in unsigned(15 downto 0);
		
		-- The two operands. One at at time.
		ack : out std_logic;              -- Computation is complete.
		C   : out unsigned(15 downto 0)); -- The result.
end gcd_top;


--------------------------------------------------------------------------------
-- A specification of the GCD module (no indication of an implementation)
--
--    1) Implements the correct handshaking on the interface of the module
--       (including some arbitrary time delays in the handshaking).
--    2) GCD is calculated by an algorithm (variables, zero delay, ...)
--    3) Allows simulation of the entire test bench.
--       (The starting point for the actual design work)
--
------------------------------------------------------------------------------

architecture specification of gcd_top is
begin
	process
		variable RegA : unsigned(15 downto 0);
		variable RegB : unsigned(15 downto 0);
	begin

		ack <= '0';
		C   <= (others => 'Z');

		-- And endless loop.
		loop
			-- First handshake: Input of A operand

			-- Handshake phase 1.
			wait until req'event and req = '1';

			-- The operand is stored in the register.
			RegA := AB;

			-- Handshake phase 2.
			ack <= '1' after 15 ns;

			-- Handshake phase 3.
			wait until req'event and req = '0';

			-- Handshake phase 4. Handshake protocol complete.
			ack <= '0' after 5 ns;

			-- Second handshake: Input of B operand, computation and output of result

			-- Handshake phase 1.
			wait until req'event and req = '1';

			-- The operand is stored in the register.
			RegB := AB;

			-- The algorithm as presented in the problem text.
			while RegA /= RegB loop
				if RegA > RegB then
					RegA := RegA - RegB;
				else
					RegB := RegB - RegA;
				end if;
			end loop;

			-- Output the result after a small delay. The delay makes the waveforms
			-- for a simulation easier to read.
			C <= RegA after 15 ns;

			-- Handshake phase 2.
			ack <= '1' after 15 ns;

			-- Handshake phase 3.
			wait until req'event and req = '0';

			-- Handshake phase 4. Handshake protocol complete. Remove result from
			-- output.
			ack <= '0' after 5 ns;
			C   <= (others => 'Z') after 5 ns;

		end loop;
	end process;
end specification;
