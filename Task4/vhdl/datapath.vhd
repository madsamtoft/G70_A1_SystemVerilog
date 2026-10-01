library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
  port (
    clk      : in  std_logic;
    ABorALU  : in  std_logic;
    LDA      : in  std_logic;
	  LDB      : in  std_logic;
    fn       : in  std_logic_vector(1 downto 0);
    AB       : in  unsigned(15 downto 0);
    C        : out unsigned(15 downto 0);
	  Z        : out std_logic;
	  N        : out std_logic
  );
end entity datapath;

architecture structural of datapath is
	signal Y     			: unsigned(15 downto 0);
	signal C_int 			: unsigned(15 downto 0);
	signal RegA, RegB : unsigned(15 downto 0);
begin

	mux_inst : entity work.mux
		port map (
			data_in1 => AB,
			data_in2 => Y,
			s => ABorALU,
			data_out => C_int
		);

	regA_inst : entity work.reg
		port map (
			clk => clk,
			en => LDA,
			data_in => C_int,
			data_out => RegA
		);

	regB_inst : entity work.reg
		port map (
			clk => clk,
			en => LDB,
			data_in => C_int,
			data_out => RegB
		);

	alu_inst : entity work.alu
		port map (
			A => RegA,
			B => RegB,
			fn => fn,
			C => Y,
			Z => Z,
			N => N
		);

	buf_inst : entity work.buf
		port map (
			data_in => RegA,
			data_out => C
		);

end architecture structural;