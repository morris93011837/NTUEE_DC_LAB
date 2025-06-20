	component rsa_qsys is
		port (
			clk_clk         : in  std_logic := 'X'; -- clk
			reset_reset_n   : in  std_logic := 'X'; -- reset_n
			altpll_100k_clk : out std_logic;        -- clk
			altpll_12m_clk  : out std_logic         -- clk
		);
	end component rsa_qsys;

	u0 : component rsa_qsys
		port map (
			clk_clk         => CONNECTED_TO_clk_clk,         --         clk.clk
			reset_reset_n   => CONNECTED_TO_reset_reset_n,   --       reset.reset_n
			altpll_100k_clk => CONNECTED_TO_altpll_100k_clk, -- altpll_100k.clk
			altpll_12m_clk  => CONNECTED_TO_altpll_12m_clk   --  altpll_12m.clk
		);

