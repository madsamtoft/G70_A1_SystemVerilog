-- -----------------------------------------------------------------------------
--
--  Title      :  System Verilog FSMD implementation template for GCD
--             :
--  Developers :  Otto Westy Rasmussen
--             :
--  Purpose    :  This is a template for the FSMD (finite state machine with datapath)
--             :  implementation of the GCD circuit
--             :
--  Revision   :  02203 fall 2025 v.1.0
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

architecture stein_fsmd of gcd is

  type state_type is (
    op_a_await,
    op_a_release,
    op_b_await,
    calculate,
    result_release
  );

  subtype shift_type is unsigned(3 downto 0);

  signal state, next_state : state_type;
  signal reg_a, next_reg_a : unsigned(15 downto 0);
  signal reg_b, next_reg_b : unsigned(15 downto 0);
  signal common_shift, next_common_shift : shift_type;

  -- Count trailing zeros of a nonzero 16-bit value (return zero for zero)
  function ctz16(value : unsigned(15 downto 0)) return shift_type is
    variable bits_left : unsigned(15 downto 0);
    variable count     : shift_type;
  begin
    bits_left := value;
    count := (others => '0');
    if bits_left(7 downto 0) = 0 then
      count(3) := '1';
      bits_left := shift_right(bits_left, 8);
    end if;
    if bits_left(3 downto 0) = 0 then
      count(2) := '1';
      bits_left := shift_right(bits_left, 4);
    end if;
    if bits_left(1 downto 0) = 0 then
      count(1) := '1';
      bits_left := shift_right(bits_left, 2);
    end if;
    if bits_left(0) = '0' then
      count(0) := '1';
    end if;
    if value = 0 then
      return to_unsigned(0, 4);
    else
      return count;
    end if;
  end function ctz16;

begin

  stein_cl : process(all)
    variable sub_left, sub_right : unsigned(15 downto 0);
    variable difference          : unsigned(15 downto 0);
    variable result_base         : unsigned(15 downto 0);
    variable a_gt_b, both_odd    : boolean;
    variable normalize_input, normalized_value, normalized_b : unsigned(15 downto 0);
    variable normalize_shift, b_shift, shared_shift : shift_type;
  begin
    next_state <= state;
    next_reg_a <= reg_a;
    next_reg_b <= reg_b;
    next_common_shift <= common_shift;

    ack <= '0';
    C   <= reg_a;
    result_base := reg_a;

    -- Select larger minus smaller for one shared subtractor.
    a_gt_b := reg_a > reg_b;
    if (a_gt_b) then
      sub_left  := reg_a;
      sub_right := reg_b;
    else
      sub_left  := reg_b;
      sub_right := reg_a;
    end if;
    difference := sub_left - sub_right;

    -- Share one normalization lane between A and the odd-pair difference.
    both_odd := (reg_a(0) = '1') and (reg_b(0) = '1');
    if both_odd then
      normalize_input := difference;
    else
      normalize_input := reg_a;
    end if;
    normalize_shift := ctz16(normalize_input);
    normalized_value := shift_right(normalize_input, to_integer(normalize_shift));

    -- A second lane allows both initial operands to normalize together.
    b_shift := ctz16(reg_b);
    normalized_b := shift_right(reg_b, to_integer(b_shift));
    if normalize_shift < b_shift then
      shared_shift := normalize_shift;
    else
      shared_shift := b_shift;
    end if;

    case state is
      when op_a_await =>
        if (req = '1') then
          next_reg_a <= AB;
          next_common_shift <= (others => '0');
          next_state <= op_a_release;
        end if;

      when op_a_release =>
        ack <= '1';
        if (req = '0') then
          next_state <= op_b_await;
        end if;

      when op_b_await =>
        if (req = '1') then
          next_reg_b <= AB;
          next_state <= calculate;
        end if;

      when calculate =>
        -- Detect completion independently of subtractor
        if ((reg_a = 0) or (reg_b = 0) or (reg_a = reg_b) or (reg_a = 1) or (reg_b = 1)) then
          if (reg_a = 0) then
            result_base := reg_b;
          elsif (reg_b = 0) then
            result_base := reg_a;
          elsif ((reg_a = 1) or (reg_b = 1)) then
            result_base := to_unsigned(1, 16);
          end if;

          -- Restore common power of two into existing result register.
          next_reg_a <= shift_left(result_base, to_integer(common_shift));
          next_state <= result_release;
        elsif (not both_odd) then
          -- Normalize both operands fully
          next_reg_a <= normalized_value;
          next_reg_b <= normalized_b;
          next_common_shift <= shared_shift;
        else
          if (a_gt_b) then
            next_reg_a <= normalized_value;
          else
            next_reg_b <= normalized_value;
          end if;
        end if;

      when result_release =>
        ack <= '1';
        if (req = '0') then
          next_state <= op_a_await;
        end if;

      when others =>
        next_state <= op_a_await;
    end case;
  end process stein_cl;

  seq : process(clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        state <= op_a_await;
        reg_a <= (others => '0');
        reg_b <= (others => '0');
        common_shift <= (others => '0');
      else
        state <= next_state;
        reg_a <= next_reg_a;
        reg_b <= next_reg_b;
        common_shift <= next_common_shift;
      end if;
    end if;
  end process seq;

end architecture stein_fsmd;