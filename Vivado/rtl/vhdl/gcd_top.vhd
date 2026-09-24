-- -----------------------------------------------------------------------------
--
--  Title      :  Implementation of the GCD with debouncer
--             :
--  Developers :  Jens Sparsø, Rasmus Bo Sørensen and Mathias Møller Bruhn
--          :
--  Purpose    :  This design instantiates a debouncer and an implementation of GCD
--             :
--  Revision   :  02203 fall 2022 v.7.0
--
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gcd_top is
  generic (
    n     : integer := 20
  );
  port (
    clk   : in std_logic;               -- the clock signal.
    reset : in  std_logic;              -- reset the module.
    req   : in  std_logic;              -- input operand / start computation.
    AB    : in  unsigned(15 downto 0);  -- bus for a and b operands.
    ack   : out std_logic;              -- last input received / computation is complete.
    C     : out unsigned(15 downto 0)); -- the result.
end gcd_top;


architecture fsmd_io of gcd_top is

  component debounce
    generic (
      n        : integer
    );
    port (
      clk      : in std_logic;
      reset    : in  std_logic;
      sw       : in  std_logic;
      db_level : out std_logic;
      db_tick  : out std_logic
    );
  end component;

  component gcd
    port (
      clk   : in std_logic;              -- the clock signal.
      reset : in  std_logic;             -- reset the module.
      req   : in  std_logic;             -- input operand / start computation.
      AB    : in  unsigned(15 downto 0); -- bus for a and b operands.
      ack   : out std_logic;             -- input received / computation is complete.
      C     : out unsigned(15 downto 0)  -- the result.
    );
  end component;

  signal db_req : std_logic;

begin

    u1 : debounce 
        generic map (n => n) 
        port map (clk => clk, reset => reset, sw => req, db_level => db_req, db_tick => open);
    u2 : gcd 
        port map (clk => clk, reset => reset, req => db_req, AB => AB, ack => ack, C => C);

end fsmd_io;
