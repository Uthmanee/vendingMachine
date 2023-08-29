library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity VendingMachine is
    port (
        clk50: in  std_logic;
        SW : in  std_logic_vector(9 downto 0);
        LEDR : out std_logic_vector(9 downto 0);
        HEX0 : out std_logic_vector(7 downto 0);
        HEX1 : out std_logic_vector(7 downto 0);
        HEX2 : out std_logic_vector(7 downto 0);
        HEX3 : out std_logic_vector(7 downto 0);
        HEX4 : out std_logic_vector(7 downto 0);
        HEX5 : out std_logic_vector(7 downto 0)
    );
end VendingMachine;

architecture ctrller of VendingMachine is
    type State_Type is (init, idle, cash, cash5, cash10, cashInput, disp, cola, sprite, drinkInput, change, displayBalance); 
    -- cash5 & cash 10 are states that display the cash denominations that can be input into the vending machine.
    -- cashInput is a state where cash (5 or 10 naira) is input into the vending machine
    -- cola & sprite are states that display the available drinks
    signal pres_state, next_state : State_Type := init;
    signal reset : std_logic;
    signal proceed : std_logic;
    signal proceed2 : std_logic;
    -- For creating 1 Hz Clock 
    constant clkFreq : integer := 50000000;
    signal   cntrclk : integer := 0;
    signal   clk     : std_logic := '0';
    -- Signal used as a counter to determine how long the cash denomination display states (cash5 & cash10) lasts for
    constant maxCntr : integer := 2;
    signal   cntr    : integer range 0 to maxCntr := 0;
	 
    -- Variable used to monitor customer's balance in the vending machine
	signal   balance  : integer := 0;
    signal deposit  : integer := 0;
    -- Drinks price
    constant spritePrice : integer := 25;
    constant colaPrice : integer := 20;

    -- Maximum and minimum possible 
    constant minCost : integer := 20;
    constant maxCost : integer := 50;

    -- Define constants for displaying specific things on the HEX displays with no DP
    constant zero  : std_logic_vector(7 downto 0) := "11000000";
    constant one   : std_logic_vector(7 downto 0) := "11111001";
    constant two   : std_logic_vector(7 downto 0) := "10100100";
    constant three : std_logic_vector(7 downto 0) := "10110000";
    constant four  : std_logic_vector(7 downto 0) := "10011001";
    constant five  : std_logic_vector(7 downto 0) := "10010010";
    constant six   : std_logic_vector(7 downto 0) := "10000010";
    constant seven : std_logic_vector(7 downto 0) := "11111000";
    constant eight : std_logic_vector(7 downto 0) := "10000000";
    constant nine  : std_logic_vector(7 downto 0) := "10011000";
    constant A     : std_logic_vector(7 downto 0) := "10001000";
    constant b     : std_logic_vector(7 downto 0) := "10000011";
    constant c     : std_logic_vector(7 downto 0) := "11000110";
    constant d     : std_logic_vector(7 downto 0) := "10100001";
    constant e     : std_logic_vector(7 downto 0) := "10000100";
    constant F     : std_logic_vector(7 downto 0) := "10001110";
    constant g     : std_logic_vector(7 downto 0) := "10010000";
    constant h     : std_logic_vector(7 downto 0) := "10001011";
    constant J     : std_logic_vector(7 downto 0) := "11100001";
    constant L     : std_logic_vector(7 downto 0) := "11000111";
    constant n     : std_logic_vector(7 downto 0) := "10101011";
    constant o     : std_logic_vector(7 downto 0) := "10100011";
    constant P     : std_logic_vector(7 downto 0) := "10001100";
    constant r     : std_logic_vector(7 downto 0) := "10101111";
    constant S     : std_logic_vector(7 downto 0) := "10010010";
    constant t     : std_logic_vector(7 downto 0) := "10000111";
    constant u     : std_logic_vector(7 downto 0) := "11100011";
  --constant y     : std_logic_vector(7 downto 0) := "10010001";
    constant z     : std_logic_vector(7 downto 0) := "10100100";
    constant dash  : std_logic_vector(7 downto 0) := "10111111";
  --constant upc_E : std_logic_vector(7 downto 0) := "10000110";
  --constant rev_E : std_logic_vector(7 downto 0) := "10110000";
  --constant rev_r : std_logic_vector(7 downto 0) := "10111011";
    constant blank : std_logic_vector(7 downto 0) := "11111111";

    -- Define vectors for HEX displays for each light config
    -- INIT
    constant hex5_init  : std_logic_vector(7 downto 0) := blank;
    constant hex4_init  : std_logic_vector(7 downto 0) := one;
    constant hex3_init  : std_logic_vector(7 downto 0) := n;
    constant hex2_init  : std_logic_vector(7 downto 0) := one;
    constant hex1_init  : std_logic_vector(7 downto 0) := t;
    constant hex0_init  : std_logic_vector(7 downto 0) := blank;

    -- IDLE
    constant hex5_idle  : std_logic_vector(7 downto 0) := blank;
    constant hex4_idle  : std_logic_vector(7 downto 0) := one;
    constant hex3_idle  : std_logic_vector(7 downto 0) := d;
    constant hex2_idle  : std_logic_vector(7 downto 0) := L;
    constant hex1_idle  : std_logic_vector(7 downto 0) := e;
    constant hex0_idle  : std_logic_vector(7 downto 0) := blank;

    -- CASH
    constant hex5_cash : std_logic_vector(7 downto 0) := blank;
    constant hex4_cash : std_logic_vector(7 downto 0) := c;
    constant hex3_cash : std_logic_vector(7 downto 0) := A;
    constant hex2_cash : std_logic_vector(7 downto 0) := S;
    constant hex1_cash : std_logic_vector(7 downto 0) := h;
    constant hex0_cash : std_logic_vector(7 downto 0) := blank;

    -- CASH5
    constant hex5_cash5 : std_logic_vector(7 downto 0) := c;
    constant hex4_cash5 : std_logic_vector(7 downto 0) := A;
    constant hex3_cash5 : std_logic_vector(7 downto 0) := S;
    constant hex2_cash5 : std_logic_vector(7 downto 0) := h;
    constant hex1_cash5 : std_logic_vector(7 downto 0) := blank;
    constant hex0_cash5 : std_logic_vector(7 downto 0) := S;

    -- CASH10
    constant hex5_cash10 : std_logic_vector(7 downto 0) := c;
    constant hex4_cash10 : std_logic_vector(7 downto 0) := A;
    constant hex3_cash10 : std_logic_vector(7 downto 0) := s;
    constant hex2_cash10 : std_logic_vector(7 downto 0) := h;
    constant hex1_cash10 : std_logic_vector(7 downto 0) := one;
    constant hex0_cash10 : std_logic_vector(7 downto 0) := zero;

    -- CASHINPUT
    constant hex5_cashInput : std_logic_vector(7 downto 0) := blank;
    constant hex4_cashInput : std_logic_vector(7 downto 0) := one;
    constant hex3_cashInput : std_logic_vector(7 downto 0) := n;
    constant hex2_cashInput : std_logic_vector(7 downto 0) := p;
    constant hex1_cashInput : std_logic_vector(7 downto 0) := u;
    constant hex0_cashInput : std_logic_vector(7 downto 0) := t;

    -- DISP
    constant hex5_disp : std_logic_vector(7 downto 0) := blank;
    constant hex4_disp : std_logic_vector(7 downto 0) := d;
    constant hex3_disp : std_logic_vector(7 downto 0) := one;
    constant hex2_disp : std_logic_vector(7 downto 0) := s;
    constant hex1_disp : std_logic_vector(7 downto 0) := p;
    constant hex0_disp : std_logic_vector(7 downto 0) := blank;

    -- COLA
    constant hex5_cola : std_logic_vector(7 downto 0) := blank;
    constant hex4_cola : std_logic_vector(7 downto 0) := c;
    constant hex3_cola : std_logic_vector(7 downto 0) := o;
    constant hex2_cola : std_logic_vector(7 downto 0) := L;
    constant hex1_cola : std_logic_vector(7 downto 0) := A;
    constant hex0_cola : std_logic_vector(7 downto 0) := blank;

    -- SPRITE
    constant hex5_sprite : std_logic_vector(7 downto 0) := s;
    constant hex4_sprite: std_logic_vector(7 downto 0) := p;
    constant hex3_sprite : std_logic_vector(7 downto 0) := r;
    constant hex2_sprite : std_logic_vector(7 downto 0) := one;
    constant hex1_sprite : std_logic_vector(7 downto 0) := t;
    constant hex0_sprite : std_logic_vector(7 downto 0) := e;

    -- DrinkInput
    constant hex5_drinkInput : std_logic_vector(7 downto 0) := blank;
    constant hex4_drinkInput: std_logic_vector(7 downto 0) := one;
    constant hex3_drinkInput : std_logic_vector(7 downto 0) := n;
    constant hex2_drinkInput : std_logic_vector(7 downto 0) := p;
    constant hex1_drinkInput : std_logic_vector(7 downto 0) := u;
    constant hex0_drinkInput : std_logic_vector(7 downto 0) := t;

    -- CHANGE
    constant hex5_change : std_logic_vector(7 downto 0) := C;
    constant hex4_change : std_logic_vector(7 downto 0) := h;
    constant hex3_change : std_logic_vector(7 downto 0) := A;
    constant hex2_change : std_logic_vector(7 downto 0) := n;
    constant hex1_change : std_logic_vector(7 downto 0) := g;
    constant hex0_change : std_logic_vector(7 downto 0) := e;

    -- DisplayBalance
    shared variable hex5_displayBalance : std_logic_vector(7 downto 0);
    shared variable hex4_displayBalance : std_logic_vector(7 downto 0);
    shared variable hex3_displayBalance : std_logic_vector(7 downto 0);
    shared variable hex2_displayBalance : std_logic_vector(7 downto 0);
    shared variable hex1_displayBalance : std_logic_vector(7 downto 0);
    shared variable hex0_displayBalance : std_logic_vector(7 downto 0);

begin
    reset <= SW(0);
    proceed <= SW(1);
    proceed2 <= SW(2);
    

    ------------------- getting 1 HZ clock from the bard
    clock_division : process(clk50)
    begin
        if rising_edge(clk50) then
            if cntrclk < integer(clkFreq/2) then
                cntrclk <= cntrclk + 1;
            else
                clk     <= not clk;
                cntrclk <= 0;
            end if;
        end if;
    end process;

    ------------------- state control
    state_control : process (clk, proceed, proceed2, reset)
    begin
        if (reset = '1') then
            LEDR(0) <= '1';
            pres_state <= idle;
        elsif (proceed = '1') then
            LEDR(1) <= '1';
        elsif (proceed2 = '1') then
            LEDR(2) <= '1';
        elsif (rising_edge(clk)) then
			LEDR(0) <= '0';
            LEDR(1) <= '0';
            LEDR(2) <= '0';
            pres_state <= next_state;
        end if;
    end process;

    next_state_logic : process (pres_state, clk, proceed, proceed2)
    begin
        if rising_edge(clk) then
            if (reset = '1') then
                next_state <= idle;
          --elsif (proceed = '1') then
              --next_state <= disp;
            else 
                case (pres_state) is
                    when init =>
                    cntr <= 0;
                    next_state <= idle;               
                    when idle =>
                        deposit <= 0;
                        balance <= 0;
                        if (proceed = '1') then
                            next_state <= cash;
                        end if;
                    when cash =>
                        -- if (proceed = '1') then
                        --     next_state <= cash5;
                        -- end if;
                        cntr <= cntr + 1;
                        if cntr = maxCntr then
                            cntr <= 0;
                            next_state <= cash5;
                        end if;
                    when cash5 =>
                        cntr <= cntr + 1;
                        if cntr = maxCntr then
                            cntr <= 0;
                            next_state <= cash10;
                        end if;
                    when cash10 =>
                        cntr <= cntr + 1;
                        if cntr = maxCntr then
                            cntr <= 0;
                            next_state <= cashInput;
                        end if;
                    when cashInput =>
                        deposit <= 0;
                        balance <= 0;
                        balance <= balance + deposit;
                        if (balance <= minCost) then
                            if (proceed = '1') then
                                deposit <= 5;
                            elsif (proceed2 = '1') then
                                deposit <= 10;
                            end if;
                        elsif (balance >= maxCost) then
                            if (proceed = '1') then
                                next_state <= disp;
                            elsif (proceed2 = '1') then
                                next_state <= disp;
                            end if;
                        elsif (balance > minCost) and (balance < maxCost) then
                            if (proceed = '1') then
                                next_state <= disp;
                            elsif (proceed2 = '1') then
                                deposit <= 10;
                            end if;
                        end if;
                    when disp =>
                        cntr <= cntr + 1;
                        if cntr = maxCntr then
                            cntr <= 0;
                            next_state <= cola;
                        end if;
                    when cola =>
                        cntr <= cntr + 1;
                        if cntr = maxCntr then
                            cntr <= 0;
                            next_state <= sprite;
                    end if;
                    when sprite =>
                        cntr <= cntr + 1;
                        if cntr = maxCntr then
                            cntr <= 0;
                            next_state <= drinkInput;
                    end if;
                    when drinkInput =>
                        --if switch1, select coke then reset balance (balance = balance - cokePrice) and go to next state 
                        --if switch2, select sprite then reset balance (balance = balance - spritePrice) and go to next state
                        if (proceed = '1') then
                            balance <= balance - colaPrice;
                            next_state <= change;
                        elsif (proceed2 = '1') then
                            balance <= balance - spritePrice;
                            next_state <= change;
                        end if;
                    when change =>
                        if (proceed = '1') then
                            if (balance = 0) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := blank;
                                hex0_displayBalance := zero;
                            elsif (balance = 5) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := blank;
                                hex0_displayBalance := five;
                            elsif (balance = 10) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := one;
                                hex0_displayBalance := zero;
                            elsif (balance = 15) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := one;
                                hex0_displayBalance := five;
                            elsif (balance = 20) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := two;
                                hex0_displayBalance := zero;
                            elsif (balance = 25) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := two;
                                hex0_displayBalance := five;
                            elsif (balance = 30) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := three;
                                hex0_displayBalance := zero;
                            elsif (balance = 35) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := three;
                                hex0_displayBalance := five;
                            elsif (balance = 40) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := four;
                                hex0_displayBalance := zero;
                            elsif (balance = 45) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := four;
                                hex0_displayBalance := five;
                            elsif (balance = 50) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := five;
                                hex0_displayBalance := zero;
                            elsif (balance = 55) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := five;
                                hex0_displayBalance := five;
                            elsif (balance = 60) then
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := six;
                                hex0_displayBalance := zero;
                            else 
                                hex5_displayBalance := blank;
                                hex4_displayBalance := blank;
                                hex3_displayBalance := blank;
                                hex2_displayBalance := blank;
                                hex1_displayBalance := dash;
                                hex0_displayBalance := dash;
                            end if;
                            next_state <= displayBalance;
                    end if;
                    when displayBalance =>
                        if (proceed = '1') then
                            balance <= 0;
                            next_state <= idle;
                    end if;
                    when others => 
                        next_state <= idle;
                end case;
            end if;
        end if;
    end process;

    output_logic : process (pres_state)
    begin
        case (pres_state) is
            when init =>
                HEX5 <= hex5_init;
                HEX4 <= hex4_init;
                HEX3 <= hex3_init;
                HEX2 <= hex2_init;
                HEX1 <= hex1_init;
                HEX0 <= hex0_init;
            when idle => 
                HEX5 <= hex5_idle;
                HEX4 <= hex4_idle;
                HEX3 <= hex3_idle;
                HEX2 <= hex2_idle;
                HEX1 <= hex1_idle;
                HEX0 <= hex0_idle;
            when cash =>
                HEX5 <= hex5_cash;
                HEX4 <= hex4_cash;
                HEX3 <= hex3_cash;
                HEX2 <= hex2_cash;
                HEX1 <= hex1_cash;
                HEX0 <= hex0_cash;
            when cash5 =>
                HEX5 <= hex5_cash5;
                HEX4 <= hex4_cash5;
                HEX3 <= hex3_cash5;
                HEX2 <= hex2_cash5;
                HEX1 <= hex1_cash5;
                HEX0 <= hex0_cash5;
            when cash10 =>
                HEX5 <= hex5_cash10;
                HEX4 <= hex4_cash10;
                HEX3 <= hex3_cash10;
                HEX2 <= hex2_cash10;
                HEX1 <= hex1_cash10; 
                HEX0 <= hex0_cash10;
            when cashInput =>
                HEX5 <= hex5_cashInput;
                HEX4 <= hex4_cashInput;
                HEX3 <= hex3_cashInput;
                HEX2 <= hex2_cashInput;
                HEX1 <= hex1_cashInput; 
                HEX0 <= hex0_cashInput;
            when disp =>
                HEX5 <= hex5_disp;
                HEX4 <= hex4_disp;
                HEX3 <= hex3_disp;
                HEX2 <= hex2_disp;
                HEX1 <= hex1_disp;
                HEX0 <= hex0_disp;	
            when cola =>
                HEX5 <= hex5_cola;
                HEX4 <= hex4_cola;
                HEX3 <= hex3_cola;
                HEX2 <= hex2_cola;
                HEX1 <= hex1_cola;
                HEX0 <= hex0_cola;	
            when sprite =>
                HEX5 <= hex5_sprite;
                HEX4 <= hex4_sprite;
                HEX3 <= hex3_sprite;
                HEX2 <= hex2_sprite;
                HEX1 <= hex1_sprite;
                HEX0 <= hex0_sprite;	
            when drinkInput =>
                HEX5 <= hex5_drinkInput;
                HEX4 <= hex4_drinkInput;
                HEX3 <= hex3_drinkInput;
                HEX2 <= hex2_drinkInput;
                HEX1 <= hex1_drinkInput;
                HEX0 <= hex0_drinkInput;
            when displayBalance =>
                HEX5 <= hex5_displayBalance;
                HEX4 <= hex4_displayBalance;
                HEX3 <= hex3_displayBalance;
                HEX2 <= hex2_displayBalance;
                HEX1 <= hex1_displayBalance;
                HEX0 <= hex0_displayBalance;
            when change =>
                HEX5 <= hex5_change;
                HEX4 <= hex4_change;
                HEX3 <= hex3_change;
                HEX2 <= hex2_change;
                HEX1 <= hex1_change;
                HEX0 <= hex0_change;
            when others => 
                HEX5 <= hex5_idle;
                HEX4 <= hex4_idle;
                HEX3 <= hex3_idle;
                HEX2 <= hex2_idle;
                HEX1 <= hex1_idle;
                HEX0 <= hex0_idle;
        end case;
    end process;
end architecture ctrller;