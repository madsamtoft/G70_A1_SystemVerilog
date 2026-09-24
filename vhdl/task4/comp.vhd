-- -----------------------------------------------------------------------------
--
--  Title      :  Components for the GCD module
--             :
--  Developers :  Jens Sparsø and Rasmus Bo Sørensen
--             :
--  Purpose    :  This design contains models of the components that must be
--             :  used to implement the GCD module.
--             :
--  Note       :  All the components have a generic parameter that sets the
--             :  bit-width of the component. This defaults to 16 bits, so in
--             :  this assignment there is no need to change it.
--             :
--  Revision   :  02203 fall 2017 v.5.0
--
-- -----------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- A buffer. Defaults to a width of 16 bits. Note the special
-- statement that assigns the input to the output. It is similar to a simple
-- IF-statement but can be used outside a process.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buf is
    generic (N:     natural := 16);				-- width of inputs.
    port (data_in:  in  unsigned(N downto 1);	-- input.
          data_out: out unsigned(N downto 1));	-- output.
end buf;

architecture behaviour of buf is
begin
    data_out <= data_in;
end behaviour;


--------------------------------------------------------------------------------
-- A 2 to 1 multiplexor. Defaults to a width of 16 bits.
-- If select (s) is 0 input 1 will be choosen else input 2
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux is
    generic (N:     natural := 16);				-- width of inputs and output.
    port (data_in1:  in  unsigned(N downto 1);	-- inputs.
          data_in2:  in unsigned(N downto 1);
          s       :  in std_logic;				-- select signal.
          data_out:  out  unsigned(N downto 1)	-- output.
          );
end mux;

architecture behaviour of mux is
begin
    data_out <= data_in1 when s = '0' else data_in2;
end behaviour;

--------------------------------------------------------------------------------
-- A generic positive edge-triggered register with enable. Width defaults to
-- 16 bits.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg is
    generic (N:     natural := 16);				-- width of inputs.
    port (clk:      in  std_logic;				-- clock signal.
          en:       in  std_logic;				-- enable signal.
          data_in:  in  unsigned(N downto 1);	-- input data.
          data_out: out unsigned(N downto 1));	-- output data.
end reg;

architecture behaviour of reg is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                data_out <= data_in;
            end if;
        end if;
    end process;
end behaviour;

--------------------------------------------------------------------------------
-- A simple ALU that works on numbers in two's complement representation. The
-- width defaults to 16 bits. The ALU has the following four functions encoded
-- in the signal "fn":
-- fn = 00 : C = A - B
-- fn = 01 : C = B - A
-- fn = 10 : C = A
-- fn = 11 : C = B
-- The ALU sets the two flags "Z" and "N" which indicates if the result was zero
-- or negative.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    generic (W:     natural := 16);						-- width of inputs.
    port (A, B:     in unsigned(w downto 1);			-- input operands.
          fn:       in std_logic_vector(1 downto 0); 	-- function.
          C:        out unsigned(W downto 1);			-- result.
          Z:        out std_logic;          			-- result = 0 flag.
          N:        out std_logic);         			-- result neg flag.
end alu;

architecture behaviour of alu is
    signal i_C: unsigned(W downto 1);

    constant zero: unsigned(W downto 1) := (others => '0');
begin
    C <= i_C;

    with fn select
        i_C <= A - B when "00",
               B - A when "01",
               A when "10",
               B when others;           -- "11"

    N <= i_C(W);
    Z <= '1' when i_C = zero else '0';
end behaviour;
