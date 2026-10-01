library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gcd_module is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    req   : in  std_logic;
    AB    : in  unsigned(15 downto 0);
    ack   : out std_logic;
    C     : out unsigned(15 downto 0)
  );
end entity gcd_module;

architecture structural of gcd_module is

  signal N, Z     : std_logic;
  signal LDA, LDB : std_logic;
  signal ABorALU  : std_logic;
  signal fn       : std_logic_vector(1 downto 0);

begin

  fsm_inst : entity work.fsm
    port map (
      clk   => clk,
      reset => reset,
      req   => req,
      N     => N,
      Z     => Z,
      ack   => ack,
      LDA   => LDA,
      LDB   => LDB,
      ABorALU => ABorALU,
      fn    => fn
    );

  datapath_inst : entity work.datapath
    port map (
      clk      => clk,
      ABorALU  => ABorALU,
      LDA      => LDA,
      LDB      => LDB,
      fn       => fn,
      AB       => AB,
      C        => C,
      Z        => Z,
      N        => N
    );

end architecture structural;