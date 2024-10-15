library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity soda is
  port (
      clk, clk_fpga: std_logic;
      reset: in bit;
      button: in bit;
      coin: in bit_vector(2 downto 0);

      current: out unsigned(4 downto 0) := (others => '0');
      sodaDrink: out bit := '0';
      exchange: out bit := '0';
      stateOut: out bit := '0'
       );
end soda;

architecture behaviour of soda is
  type states is (noMoney, money);
  signal state: states;
  signal currentMoney: unsigned(4 downto 0) := (others => '0');

  signal clock: std_logic;
  
  component Debouncing_Button_VHDL is
    port(
          button: in std_logic;
          clk: in std_logic;
          
          buttonDebounce: out std_logic
        );
  end component;

  function coinValue(coin : in bit_vector(2 downto 0))
    return unsigned is
      variable outValue : unsigned(4 downto 0) := (others => '0');
  begin
    case coin is
      when "001" => outValue := outValue + 2;
      when "010" => outValue := outValue + 5;
      when "011" => outValue := outValue + 10;
      when "100" => outValue := outValue + 20;
    end case;
    return outValue;
  end function coinValue;
begin
  debouncer: Debouncing_Button_VHDL
    port map (
                button => clk, clk => clk_fpga, buttonDebounce => clock
             );
  process(clock)
  begin
    if(reset = '1') then
      state <= noMoney;
      sodaDrink <= '0';
      exchange <= '0';
      stateOut <= '0';
      current <= "00000";
      currentMoney <= "00000";

    elsif (clock'event) and (clock = '1') then
      case state is
        when noMoney => 
          if (coin /= "000") then 
            state <= money;
            current <= currentMoney + coinValue(coin);
            currentMoney <= currentMoney + coinValue(coin);
            stateOut <= '1';
          else
            sodaDrink <= '0';
            exchange <= '0';
          end if;

        when money =>
          if(currentMoney + coinValue(coin) = 20 and button = '1') then
            state <= noMoney;
            stateOut <= '0';
            sodaDrink <= '1';
            current <= "00000";
            currentMoney <= "00000";

          elsif(currentMoney + coinValue(coin) < 20 and button = '1') then
            state <= noMoney;
            stateOut <= '0';
            exchange <= '1';
            current <= "00000";
            currentMoney <= "00000";

          elsif(currentMoney + coinValue(coin) > 20) then 
            state <= noMoney;
            stateOut <= '0';
            exchange <= '1';
            current <= "00000";
            currentMoney <= "00000";

          else 
            current <= currentMoney + coinValue(coin);
            currentMoney <= currentMoney + coinValue(coin);
          end if;
      end case;
    end if;
  end process;
end behaviour;
