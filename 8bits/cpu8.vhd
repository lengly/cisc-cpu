library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity CPU8 is
generic(
	size:integer:=8
);
port(
	db:	inout std_logic_vector(size-1 downto 0);
	ab:	inout std_logic_vector(15 downto 0);
	mwr,mrd,iow,ior:inout std_logic;
	co:	inout std_logic_vector(31 downto 0);
	ci:	out std_logic_vector(31 downto 0);
	clk,run,reset,krix,prix:in std_logic;
	mux:in std_logic_vector(2 downto 0)
);
end CPU8;

architecture behavior of CPU8 is
signal MCLK, MPCK, MICK, WRC, PCK, CA, CT, CC, CCI, CA1, CA2, CCK, ZCK, SCK: std_logic;--clks
signal prst, mclr:std_logic;
signal crdx,cwrx:std_logic;
signal mpc,md:std_logic_vector(9 downto 0);
signal mir:std_logic_vector(29 downto 0);
signal mxc,mxb,ssp:std_logic_vector(1 downto 0);
signal pld,s:std_logic_vector(2 downto 0);
signal mpld,pinc,mxa,mxe,cp,zp,ob,ga2,ahs,ga1,gi,gt,gc,asrc,ga,wre:std_logic;--control signals
signal a:std_logic_vector(size downto 0);--alu's a
signal b:std_logic_vector(size downto 0);--alu's b
signal ff:std_logic_vector(size downto 0);--alu's full output(ff8 is cout and ff7-0 is fout)
signal ir:std_logic_vector(size-1 downto 0);--ir
signal rs:std_logic_vector(2 downto 0);--register selection
signal obtemp:std_logic_vector(size-1 downto 0);--buffer
signal adr,pc,sp:std_logic_vector(15 downto 0);
signal fout,adrh,adrl,pch,pcl,rout,tmp,ra,act,fb,fa,r0,r1,r2,r3,r4,r5,r6,r7:std_logic_vector(size-1 downto 0);
signal zy,cy,cout,aout,pldr:std_logic;
signal mxd_in:std_logic_vector(5 downto 0);
constant zero:std_logic_vector(size-1 downto 0):=(others=>'0');

begin
--ci31~10--
	ci(31 downto 24) 	<=	A 				when mux="000" else	 --CI
						pc(15 downto 8)	when mux="001" else	 --EX4
						adrh 			when mux="010" else	 --EX2
						r0 				when mux="011" else	 --EX6
						r2 				when mux="100" else	 --EX1
						r4 				when mux="101" else	 --EX5
						r6 				when mux="110" else	 --EX3
						tmp;								 --EX7
	ci(23 downto 16) 	<=	IR 				when mux="000" else
						pc(7 downto 0) 	when mux="001" else
						adrl 			when mux="010" else
						r1 				when mux="011" else
						r3 				when mux="100" else
						r5 				when mux="101" else
						r7 				when mux="110" else
						act;
	ci(15 downto 12) 	<=	sp(15 downto 12) 	when mux="000" else
						sp(11 downto 8) 	when mux="001" else
						sp(7 downto 4) 	when mux="010" else
						sp(3 downto 0);
	ci(11) 			<=	krix 			when mux="000" else
						prix 			when mux="001" else
						pldr 			when mux="010" else
						cy 				when mux="011" else
						zy;
	ci(10) 			<= 	cwrx;
	
--clocks--
	pMCLK:process(mclk,clk,run,reset)
	begin
		if run='0' or reset='0' then
			mclk<='0';
		elsif clk'event and clk='0' then
			mclk<=not mclk;
		end if;
	end process;
	
	process(mclk,reset)
	begin
		if reset='0' then
			mclr<='0';
		elsif mclk'event and mclk='1' then
			mclr <= run;
		end if;
	end process;
	
	mpck<=not mclk and clk;
	mick<=not mpck;
	
	wrc<=mclk;	--寄存器Ri时钟
	pck<=mclk;	--PC时钟
	ca<=mclk;	--A时钟
	ct<=mclk;	--TMP时钟
	cc<=mclk;	--ACT时钟
	cci<=mclk;	--IR时钟
	ca1<=mclk;	--ADRH时钟
	ca2<=mclk;	--ADRL时钟
	cck<=mclk;	--CR时钟
	zck<=mclk;	--ZY时钟
	sck<=mclk;	--SP时钟
	
--Unit_IO--
	iow<=not ab(15) or not ab(1) or (cwrx or not mclk) or not clk;
	ior<=not ab(15) or not ab(0) or (crdx or not mclk);


--CTRL_MIR--
	pmir:process(mick)
	begin
		if mick'event and mick='1' then
			mir <= co(29 downto 0);
		end if;
	end process;
	cwrx<=mir(29);
	crdx<=mir(28);
	mpld<=mir(27);
	mxc(1)<=mir(26);mxc(0)<=mir(25);
	ssp(1)<=mir(24);ssp(0)<=mir(23);
	pinc<=mir(22);
	pld(2)<=mir(21);pld(1)<=mir(20);pld(0)<=mir(19);
	mxa<=mir(18);
	s(2)<=mir(17);s(1)<=mir(16);s(0)<=mir(15);
	mxe<=mir(14);
	cp<=mir(13);
	zp<=mir(12);
	mxb(1)<=mir(11);mxb(0)<=mir(10);
	ob<=mir(9);
	ga2<=mir(8);
	ahs<=mir(7);
	ga1<=mir(6);
	gi<=mir(5);
	gt<=mir(4);
	gc<=mir(3);
	asrc<=mir(2);
	ga<=mir(1);
	wre<=mir(0);

--Unit_A--
	pA:process(ca,asrc,ga,db)
	begin
		if ca'event and ca='0' then
			if ga='0' then
				ra <= db;
			elsif asrc='0' then
				aout <= ra(0);
				rolact:for i in 6 downto 1 loop
					ra(i - 1) <= ra(i);
				end loop;
			end if;
		end if;
	end process;
	
--Unit_ACT--
	pACT:process(cc,gc,ra)
	begin
		if cc'event and cc='0' then
			if gc='0' then
				act<=ra; 
			end if;
		end if;
	end process;
	fa<=act;
	
--Unit_TMP--
	pTMP:process(ct,gt,db)
	begin
		if ct'event and ct='0' then
			if gt='0' then
				tmp <= db;
			end if;
		end if;
	end process;
	
--Unit_registers--
	rs(2 downto 0) <= ir(2 downto 0);
	pRi:process(wrc,wre,rs)
	begin
		if wrc'event and wrc='0' then
			if wre='0' then
				case rs is
				when "000" => r0 <= db;
				when "001" => r1 <= db;
				when "010" => r2 <= db;
				when "011" => r3 <= db;
				when "100" => r4 <= db;
				when "101" => r5 <= db;
				when "110" => r6 <= db;
				when others => r7 <= db;
				end case;
			end if;
		end if;
	end process;
	with rs select
	rout <=	r0 when "000",
			r1 when "001",
			r2 when "010",
			r3 when "011",
			r4 when "100",
			r5 when "101",
			r6 when "110",
			r7 when others;

--Unit_ALU--
	a <= '0' & fa;
	b <= '0' & fb;
	cout <= ff(size);
	ff1:for i in size - 1 downto 0 generate
		fout(i) <= ff(i);
	end generate;
	pALU:process(a,b,s)
	begin
		case S is
			when "000" => ff <= a + b;
			when "001" => ff <= a - b;
			when "010" => ff <= a;
			when "011" => ff <= b;
			when "100" => ff <= not b;
			when "101" => ff <= a xor b;
			when others => ff <= (others => '0');
		end case;
	end process;
	
--Unit_CY--
	pCY:process(cp,cck)
	begin
		if cck'event and cck='0' then
			if cp='0' then
				if mxe='0' then
					cy<=cout;
				else 
					cy<=aout;
				end if;
			end if;
		end if;
	end process;
	
--Unit_ZY--
	pZY:process(zp,zck)
	begin
		if zck'event and zck='0' then
			if zp='0' then
				if fout = zero then
					zy <= '1';
				else
					zy <= '0';
				end if;
			end if;
		end if;
	end process;

--Unit_OB--
	pOB:process(ob,obtemp)
	begin
		if ob='0' then
			db <= obtemp;
		else
			db <= "ZZZZZZZZ";
		end if;
	end process;
	
--Unit_IR--
	pIR:process(db,cci,gi)
	begin
		if cci'event and cci='0'and gi='0' then
			ir <= db;
		end if;
	end process;
	
--Unit_ADR--
	pADRH:process(db,ca1,ga1,ahs)
	begin
		if ca1'event and ca1='0' then
			if ga1='0' then 
				adrh<=db;
			end if;
			if ahs='0' then
				adrh<="01111110"; --7E
			end if;
		end if;
	end process;
	pADRL:process(db,ca2,ga2)
	begin
		if ca2'event and ca2='0' and ga2='0' then
			adrl<=db;
		end if;
	end process;
	adr<=adrh & adrl;

--Unit_PC--
	prst<=reset;
	pPC:process(pinc,prst,pldr,pck)
	begin
		if prst='0' then 
			pc <= (others => '0');
		elsif pck'event and pck='0' then
			if pinc='0' then
				pc <= pc + 1;
			elsif pldr='1' then
				pc <= ab;
			end if;
		end if;
	end process;
	pc1:for i in size - 1 downto 0 generate
		pch(i)<=pc(i+size);
		pcl(i)<=pc(i);
	end generate;

--Unit_MPC--
	pMPC:process(mpld,mpck,mclr)
	begin
		if mclr = '0' then
			mpc <= (others => '0');
		elsif mpck'event and mpck='1' then
			if mpld='0' then
				mpc <= md;
			else
				mpc <= mpc+1;
			end if;
		end if;
	end process;
	ci(9 downto 0) <= mpc;
	md(2 downto 0) <= "111";
	md(7 downto 3) <= ir(7 downto 3);
	md(9 downto 8) <= "00";
	
--Unit_M--
	mrd<=(crdx or not mclk) or ab(15);
	mwr<=(cwrx or not mclk) or ab(15) or not clk;
	
--Unit_SP--
	pSP:process(ssp,sck)
	begin
		if sck'event and sck='0' then
			if ssp="01" then
				sp<=sp-1;
			elsif ssp="10" then 
				sp<=sp+1;
			elsif ssp="11" then
				sp<="0111111111111111";
			end if;
		end if;
	end process;
	
--Unit_MUXA--
	pMUXA:process(rout,tmp,mxa)
	begin
		case mxa is
		when '0' => fb <= rout;
		when others => fb <= tmp;
		end case;
	end process;

--Unit_MUXB--
	pMUXB:process(fout,pch,pcl,mxb)
	begin
		case mxb is
		when "00" => obtemp <= fout;
		when "01" => obtemp <= pch;
		when "10" => obtemp <= pcl;
		when others => obtemp <= (others => '0');
		end case;
	end process;
	
--Unit_MUXC--
	pMUXC:process(pc,sp,adr,mxc)
	begin
		case mxc is
		when "00" => ab <= pc;
		when "01" => ab <= adr;
		when "10" => ab <= sp;
		when others => ab <= (others=>'0');
		end case;
	end process;
	
--Unit_MUXD--
	pMUXD:process(mxd_in,pld)
	begin
		case pld is
		when "000" =>pldr<=mxd_in(5);
		when "001" =>pldr<=mxd_in(4);
		when "010" =>pldr<=mxd_in(3);
		when "011" =>pldr<=mxd_in(2);
		when "100" =>pldr<=mxd_in(1);
		when "101" =>pldr<=mxd_in(0);
		when others=>pldr<='0';
		end case;
	end process;
	mxd_in(5)<='0';
	mxd_in(4)<=cy;
	mxd_in(3)<=not zy;
	mxd_in(2)<=not krix;
	mxd_in(1)<=not prix;
	mxd_in(0)<='1';

end behavior;
