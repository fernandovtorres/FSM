library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VendorMachine is
  port (
      clk, clk_fpga : in std_logic;
      reset : in std_logic;
      button : in std_logic;
      coin : in std_logic_vector(2 downto 0);
      
      current : out unsigned(4 downto 0);
      sodaDrink : out std_logic;
      exchange : out std_logic;
      stateOut : out std_logic
  );
end VendorMachine;

architecture behaviour of VendorMachine is
  type states is (noMoney, money);
  signal state : states := noMoney;
  signal currentMoney : unsigned(4 downto 0) := (others => '0');
  signal clock : std_logic;

  component Debouncing_Button_VHDL is
    port (
        button : in std_logic;
        clk : in std_logic;
        debounced_button : out std_logic
    );
  end component;

  function coinValue(coin : in std_logic_vector(2 downto 0))
    return unsigned is
      variable outValue : unsigned(4 downto 0) := (others => '0');
  begin
    case coin is
      when "001" => outValue := outValue + 2;
      when "010" => outValue := outValue + 5;
      when "011" => outValue := outValue + 10;
      when "100" => outValue := outValue + 20;
      when others => null;
    end case;
    return outValue;
  end function coinValue;

begin
  debouncer: Debouncing_Button_VHDL
    port map (
      button => button,
      clk => clk_fpga,
      debounced_button => clock
    );

  process(clock, reset, button)
  begin
    if reset = '1' then
      state <= noMoney;
      sodaDrink <= '0';
      exchange <= '0';
      stateOut <= '0';
      current <= (others => '0');
      currentMoney <= (others => '0');

    elsif currentMoney + coinValue(coin) > 20 then
      state <= noMoney;
      sodaDrink <= '0';
      exchange <= '1';
      current <= (others => '0');
      currentMoney <= (others => '0');
      stateOut <= '0';

    elsif button = '1' then  
      if currentMoney + coinValue(coin) = 20 then
        state <= noMoney;
        sodaDrink <= '1';
        exchange <= '0';
        current <= (others => '0');
        currentMoney <= (others => '0');
        stateOut <= '0';

      elsif currentMoney + coinValue(coin) < 20 then
        state <= noMoney;
        sodaDrink <= '0';
        exchange <= '1';
        current <= (others => '0');
        currentMoney <= (others => '0');
        stateOut <= '0';

      end if;


    elsif rising_edge(clock) then
      case state is
        when noMoney =>
          if coin /= "000" then
            state <= money;
            currentMoney <= currentMoney + coinValue(coin);
            current <= currentMoney;
            stateOut <= '1';
          else
            sodaDrink <= '0';
            exchange <= '0';
          end if;

        when money =>
          currentMoney <= currentMoney + coinValue(coin);
          current <= currentMoney;
      end case;
    end if;
  end process;
end behaviour;
