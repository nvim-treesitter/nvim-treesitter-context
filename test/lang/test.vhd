--+-------------------------------
--| Block Comment
--+-------------------------------

-- (architecture_definition)
architecture Behavioral of MyEntity is
    -- (architecture_head)
    signal clk: std_logic;
begin
    -- (concurrent_block)
    clk_process: process(clk)
    begin
        clk <= not clk after 10 ns;
        wait for 10 ns;
    end process clk_process;

    -- -- (case_statement)
    -- case state is
    --     when Idle => state <= Active;
    --     when Active => state <= Waiting;
    --     when others => state <= Idle;
    -- end case;

    -- (for_generate_statement)
    g_GENERATE_FOR: for i in 0 to 3 generate
        comp_inst: MyComponent
        port map (
            a => data(i)
        );
    end generate g_GENERATE_FOR;

    -- (if_generate_statement)
    g_GENERATE_IF: if clk = '1' generate
        comp_inst: MyComponent port map (a => clk);
    end generate g_GENERATE_IF;

    U1: MyComponent
        generic map (
            WIDTH => 8
        )
        port map (
            a => data(0)
        );

end Behavioral;

-- (configuration_declaration)
configuration Config of MyEntity is
    for Behavioral
    end for;
end configuration Config;

-- (process_statement)
process (clk)
begin
    if rising_edge(clk) then
        -- (sequential_block)
        if_statement_block: if enable = '1' then
            -- (loop_statement)
            for i in 0 to 7 loop
                -- (if_statement)
                if data(i) = '1' then
                    -- (elsif_statement)
                elsif data(i) = '0' then
                    -- (else_statement)
                else
                    data(i) <= 'X';
                end if;
            end loop;
        end if;
    end if;
end process;

-- (type_declaration)
type State_Type is (Idle, Active, Waiting);
-- (entity_declaration)
entity MyEntity is
    -- (entity_head)
    port (
        clk: in std_logic;
        reset: in std_logic;
        data: out std_logic_vector(7 downto 0)
    );
end MyEntity;

-- (package_declaration)
package MyPackage is
    -- (package_definition)
    function Add (a, b: integer) return integer;
end MyPackage;

-- (subprogram_declaration)
function Add (a, b: integer) return integer is
begin
    -- (subprogram_head)
    return a + b;
end Add;


