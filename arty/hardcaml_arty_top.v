module user_application (
    uart_rx_value,
    uart_rx_valid,
    clear_n_166,
    clear_n_200,
    clk_166,
    clk_200,
    eth_clk_rx,
    eth_clk_tx,
    eth_rx_axis_mac_tdata,
    eth_rx_axis_mac_tlast,
    eth_rx_axis_mac_tuser,
    eth_rx_axis_mac_tvalid,
    eth_tx_tready,
    led_4bits,
    led_rgb_r0,
    led_rgb_g0,
    led_rgb_b0,
    led_rgb_r1,
    led_rgb_g1,
    led_rgb_b1,
    led_rgb_r2,
    led_rgb_g2,
    led_rgb_b2,
    led_rgb_r3,
    led_rgb_g3,
    led_rgb_b3,
    uart_tx_valid,
    uart_tx_value,
    eth_tx_axis_mac_tdata,
    eth_tx_axis_mac_tlast,
    eth_tx_axis_mac_tuser,
    eth_tx_axis_mac_tvalid
);

    input [7:0] uart_rx_value;
    input uart_rx_valid;
    input clear_n_166;
    input clear_n_200;
    input clk_166;
    input clk_200;
    input eth_clk_rx;
    input eth_clk_tx;
    input [7:0] eth_rx_axis_mac_tdata;
    input eth_rx_axis_mac_tlast;
    input eth_rx_axis_mac_tuser;
    input eth_rx_axis_mac_tvalid;
    input eth_tx_tready;
    output [3:0] led_4bits;
    output led_rgb_r0;
    output led_rgb_g0;
    output led_rgb_b0;
    output led_rgb_r1;
    output led_rgb_g1;
    output led_rgb_b1;
    output led_rgb_r2;
    output led_rgb_g2;
    output led_rgb_b2;
    output led_rgb_r3;
    output led_rgb_g3;
    output led_rgb_b3;
    output uart_tx_valid;
    output [7:0] uart_tx_value;
    output [7:0] eth_tx_axis_mac_tdata;
    output eth_tx_axis_mac_tlast;
    output eth_tx_axis_mac_tuser;
    output eth_tx_axis_mac_tvalid;

    /* signal declarations */
    wire _24 = 1'b0;
    wire _25 = 1'b0;
    wire _26 = 1'b0;
    wire [7:0] _27 = 8'b00000000;
    wire [7:0] _6;
    wire _9;
    wire _28 = 1'b0;
    wire _29 = 1'b0;
    wire _30 = 1'b0;
    wire [3:0] _31 = 4'b1111;

    /* logic */
    assign _6 = uart_rx_value;
    assign _9 = uart_rx_valid;

    /* aliases */

    /* output assignments */
    assign led_4bits = _31;
    assign led_rgb_r0 = _30;
    assign led_rgb_g0 = _29;
    assign led_rgb_b0 = _28;
    assign led_rgb_r1 = _30;
    assign led_rgb_g1 = _29;
    assign led_rgb_b1 = _28;
    assign led_rgb_r2 = _30;
    assign led_rgb_g2 = _29;
    assign led_rgb_b2 = _28;
    assign led_rgb_r3 = _30;
    assign led_rgb_g3 = _29;
    assign led_rgb_b3 = _28;
    assign uart_tx_valid = _9;
    assign uart_tx_value = _6;
    assign eth_tx_axis_mac_tdata = _27;
    assign eth_tx_axis_mac_tlast = _26;
    assign eth_tx_axis_mac_tuser = _25;
    assign eth_tx_axis_mac_tvalid = _24;

endmodule
module hardcaml_arty_top (
    usb_uart_rx,
    reset,
    sys_clock,
    eth_mii_rx_clk,
    eth_mii_rx_dv,
    eth_mii_rx_er,
    eth_mii_rxd,
    eth_mii_tx_clk,
    push_buttons_4bits,
    led_4bits,
    led_rgb,
    usb_uart_tx,
    eth_mii_tx_en,
    eth_mii_txd,
    mdc
);

    input usb_uart_rx;
    input reset;
    input sys_clock;
    input eth_mii_rx_clk;
    input eth_mii_rx_dv;
    input eth_mii_rx_er;
    input [3:0] eth_mii_rxd;
    input eth_mii_tx_clk;
    input [3:0] push_buttons_4bits;
    output [3:0] led_4bits;
    output [11:0] led_rgb;
    output usb_uart_tx;
    output eth_mii_tx_en;
    output [3:0] eth_mii_txd;
    output mdc;

    /* signal declarations */
    wire _26 = 1'b0;
    wire [3:0] _27 = 4'b0000;
    wire _28 = 1'b0;
    wire _138 = 1'b0;
    wire _135;
    wire _134;
    wire _133;
    wire _132;
    wire _131;
    wire _130;
    wire _129;
    wire _125;
    wire _126;
    wire [7:0] _124 = 8'b00000000;
    wire [7:0] _123 = 8'b00000000;
    wire [7:0] _122;
    reg [7:0] _127;
    wire _128;
    reg _136;
    wire _120 = 1'b1;
    wire _119;
    wire _121;
    wire _118;
    wire _137;
    wire [1:0] _42 = 2'b00;
    wire [1:0] _32 = 2'b00;
    wire [1:0] _115;
    wire [1:0] _113;
    wire [2:0] _108 = 3'b111;
    wire [2:0] _49 = 3'b000;
    wire [2:0] _48 = 3'b000;
    wire [2:0] _61 = 3'b000;
    wire [2:0] _62;
    wire [2:0] _57 = 3'b001;
    wire [2:0] _58;
    wire [2:0] _59;
    wire _47;
    wire [2:0] _60;
    wire _45;
    wire [2:0] _63;
    wire [2:0] _4;
    reg [2:0] tx_byte_cnt;
    wire _109;
    wire [1:0] _110;
    wire [1:0] _111;
    wire [10:0] _54 = 11'b10110100101;
    wire [10:0] _73 = 11'b00000000000;
    wire [10:0] _72 = 11'b00000000000;
    wire [10:0] _70 = 11'b00000000000;
    wire [10:0] _68 = 11'b00000000001;
    wire [10:0] _69;
    wire [10:0] _65 = 11'b10110100101;
    wire _66;
    wire _64;
    wire _67;
    wire [10:0] _71;
    reg [10:0] _74;
    wire [10:0] _5;
    wire _55;
    wire _52 = 1'b0;
    wire _51 = 1'b0;
    wire _99 = 1'b1;
    wire _98;
    wire _100;
    wire _79 = 1'b0;
    wire _80;
    wire _78;
    wire _81;
    wire _76;
    wire _101;
    wire _6;
    reg _53;
    wire _56;
    wire [1:0] _106;
    wire [1:0] _77 = 2'b11;
    wire _105;
    wire [1:0] _107;
    wire [1:0] _46 = 2'b10;
    wire _104;
    wire [1:0] _112;
    wire [1:0] _44 = 2'b01;
    wire _103;
    wire [1:0] _114;
    wire [1:0] _75 = 2'b00;
    wire _102;
    wire [1:0] _116;
    wire [1:0] _7;
    reg [1:0] tx_state;
    wire _117;
    wire _139;
    wire _8;
    wire _151;
    wire _150;
    wire _149;
    wire _148;
    wire _147;
    wire _146;
    wire _145;
    wire _144;
    wire _143;
    wire _142;
    wire _141;
    wire _140;
    wire [11:0] _152;
    wire _95 = 1'b0;
    wire _94 = 1'b0;
    wire _93 = 1'b0;
    wire _92 = 1'b0;
    wire _91 = 1'b0;
    wire [7:0] _90 = 8'b00000000;
    wire _89 = 1'b0;
    wire _188 = 1'b0;
    wire _187 = 1'b0;
    reg _189;
    wire _185 = 1'b0;
    wire _184 = 1'b0;
    reg _186;
    wire _182 = 1'b0;
    wire _181 = 1'b0;
    reg _183;
    wire _179 = 1'b0;
    wire _178 = 1'b0;
    reg _180;
    wire _176 = 1'b0;
    wire _175 = 1'b0;
    reg _177;
    wire _173 = 1'b0;
    wire _172 = 1'b0;
    reg _174;
    wire _170 = 1'b0;
    wire _169 = 1'b0;
    reg _171;
    wire _157;
    wire _165;
    wire _11;
    wire _167 = 1'b0;
    wire _166 = 1'b0;
    reg _168;
    wire [7:0] _190;
    wire [7:0] _12;
    wire _251 = 1'b1;
    wire _252;
    wire [1:0] _154 = 2'b00;
    wire [1:0] _153 = 2'b00;
    wire [1:0] _248;
    wire [1:0] _245;
    wire [1:0] _244;
    wire [1:0] _246;
    wire [2:0] _239 = 3'b111;
    wire [2:0] _195 = 3'b000;
    wire [2:0] _194 = 3'b000;
    wire [2:0] _204 = 3'b000;
    wire [2:0] _200 = 3'b001;
    wire [2:0] _201;
    wire [2:0] _202;
    wire _193;
    wire [2:0] _203;
    wire _192;
    wire [2:0] _205;
    wire [2:0] _13;
    reg [2:0] rx_byte_cnt;
    wire _240;
    wire [1:0] _241;
    wire [1:0] _242;
    wire [10:0] _197 = 11'b10110100101;
    wire _198;
    wire _160 = 1'b0;
    wire _159 = 1'b0;
    wire _229 = 1'b0;
    wire _230;
    wire _231;
    wire _224 = 1'b1;
    wire _15;
    wire _225;
    wire _226;
    wire [10:0] _162 = 11'b01011010011;
    wire [10:0] _215 = 11'b00000000000;
    wire _41;
    wire [10:0] _214 = 11'b00000000000;
    wire [10:0] _212 = 11'b00000000000;
    wire [10:0] _210 = 11'b00000000001;
    wire [10:0] _211;
    wire [10:0] _207 = 11'b10110100101;
    wire _208;
    wire _206;
    wire _209;
    wire [10:0] _213;
    reg [10:0] _216;
    wire [10:0] _16;
    wire _163;
    wire _164;
    wire _227;
    wire gnd = 1'b0;
    wire _222;
    wire _221;
    wire _223;
    wire _219;
    wire _228;
    wire _217;
    wire _232;
    wire _17;
    reg _161;
    wire _199;
    wire [1:0] _237;
    wire [1:0] _220 = 2'b11;
    wire _236;
    wire [1:0] _238;
    wire [1:0] _156 = 2'b10;
    wire _235;
    wire [1:0] _243;
    wire [1:0] _218 = 2'b01;
    wire _234;
    wire [1:0] _247;
    wire [1:0] _191 = 2'b00;
    wire _233;
    wire [1:0] _249;
    wire [1:0] _18;
    reg [1:0] rx_state;
    wire _250;
    wire _253;
    wire _19;
    wire _20;
    wire _87 = 1'b0;
    wire _86 = 1'b0;
    wire _84 = 1'b0;
    wire _83 = 1'b0;
    (* ASYNC_REG="TRUE" *)
    reg _85;
    reg _88;
    wire _82;
    wire _39 = 1'b0;
    wire _38 = 1'b0;
    wire vdd = 1'b1;
    wire _35 = 1'b0;
    wire _34 = 1'b0;
    wire _33;
    (* ASYNC_REG="TRUE" *)
    reg _37;
    reg _40;
    wire _22;
    wire _24;
    wire [3:0] _30;
    wire _31;
    wire [35:0] _97;
    wire [3:0] _254;

    /* logic */
    assign _135 = _127[7:7];
    assign _134 = _127[6:6];
    assign _133 = _127[5:5];
    assign _132 = _127[4:4];
    assign _131 = _127[3:3];
    assign _130 = _127[2:2];
    assign _129 = _127[1:1];
    assign _125 = _75 == tx_state;
    assign _126 = _125 & _98;
    assign _122 = _97[24:17];
    always @(posedge _31) begin
        if (_41)
            _127 <= _124;
        else
            if (_126)
                _127 <= _122;
    end
    assign _128 = _127[0:0];
    always @* begin
        case (tx_byte_cnt)
        0: _136 <= _128;
        1: _136 <= _129;
        2: _136 <= _130;
        3: _136 <= _131;
        4: _136 <= _132;
        5: _136 <= _133;
        6: _136 <= _134;
        default: _136 <= _135;
        endcase
    end
    assign _119 = tx_state == _77;
    assign _121 = _119 ? _120 : vdd;
    assign _118 = tx_state == _46;
    assign _137 = _118 ? _136 : _121;
    assign _115 = _98 ? _44 : tx_state;
    assign _113 = _56 ? _46 : tx_state;
    assign _62 = _56 ? _61 : tx_byte_cnt;
    assign _58 = tx_byte_cnt + _57;
    assign _59 = _56 ? _58 : tx_byte_cnt;
    assign _47 = tx_state == _46;
    assign _60 = _47 ? _59 : tx_byte_cnt;
    assign _45 = tx_state == _44;
    assign _63 = _45 ? _62 : _60;
    assign _4 = _63;
    always @(posedge _31) begin
        if (_41)
            tx_byte_cnt <= _49;
        else
            tx_byte_cnt <= _4;
    end
    assign _109 = tx_byte_cnt == _108;
    assign _110 = _109 ? _77 : tx_state;
    assign _111 = _56 ? _110 : tx_state;
    assign _69 = _5 + _68;
    assign _66 = _5 == _65;
    assign _64 = ~ _53;
    assign _67 = _64 | _66;
    assign _71 = _67 ? _70 : _69;
    always @(posedge _31) begin
        if (_41)
            _74 <= _73;
        else
            _74 <= _71;
    end
    assign _5 = _74;
    assign _55 = _5 == _54;
    assign _98 = _97[16:16];
    assign _100 = _98 ? _99 : _53;
    assign _80 = _56 ? _79 : _53;
    assign _78 = tx_state == _77;
    assign _81 = _78 ? _80 : _53;
    assign _76 = tx_state == _75;
    assign _101 = _76 ? _100 : _81;
    assign _6 = _101;
    always @(posedge _31) begin
        if (_41)
            _53 <= _52;
        else
            _53 <= _6;
    end
    assign _56 = _53 & _55;
    assign _106 = _56 ? _75 : tx_state;
    assign _105 = tx_state == _77;
    assign _107 = _105 ? _106 : tx_state;
    assign _104 = tx_state == _46;
    assign _112 = _104 ? _111 : _107;
    assign _103 = tx_state == _44;
    assign _114 = _103 ? _113 : _112;
    assign _102 = tx_state == _75;
    assign _116 = _102 ? _115 : _114;
    assign _7 = _116;
    always @(posedge _31) begin
        if (_41)
            tx_state <= _42;
        else
            tx_state <= _7;
    end
    assign _117 = tx_state == _44;
    assign _139 = _117 ? _138 : _137;
    assign _8 = _139;
    assign _151 = _97[4:4];
    assign _150 = _97[5:5];
    assign _149 = _97[6:6];
    assign _148 = _97[7:7];
    assign _147 = _97[8:8];
    assign _146 = _97[9:9];
    assign _145 = _97[10:10];
    assign _144 = _97[11:11];
    assign _143 = _97[12:12];
    assign _142 = _97[13:13];
    assign _141 = _97[14:14];
    assign _140 = _97[15:15];
    assign _152 = { _140, _141, _142, _143, _144, _145, _146, _147, _148, _149, _150, _151 };
    always @(posedge _31) begin
        if (_41)
            _189 <= _188;
        else
            if (_11)
                _189 <= _186;
    end
    always @(posedge _31) begin
        if (_41)
            _186 <= _185;
        else
            if (_11)
                _186 <= _183;
    end
    always @(posedge _31) begin
        if (_41)
            _183 <= _182;
        else
            if (_11)
                _183 <= _180;
    end
    always @(posedge _31) begin
        if (_41)
            _180 <= _179;
        else
            if (_11)
                _180 <= _177;
    end
    always @(posedge _31) begin
        if (_41)
            _177 <= _176;
        else
            if (_11)
                _177 <= _174;
    end
    always @(posedge _31) begin
        if (_41)
            _174 <= _173;
        else
            if (_11)
                _174 <= _171;
    end
    always @(posedge _31) begin
        if (_41)
            _171 <= _170;
        else
            if (_11)
                _171 <= _168;
    end
    assign _157 = rx_state == _156;
    assign _165 = _157 ? _164 : gnd;
    assign _11 = _165;
    always @(posedge _31) begin
        if (_41)
            _168 <= _167;
        else
            if (_11)
                _168 <= _15;
    end
    assign _190 = { _168, _171, _174, _177, _180, _183, _186, _189 };
    assign _12 = _190;
    assign _252 = _199 ? _251 : gnd;
    assign _248 = _230 ? _218 : rx_state;
    assign _245 = _225 ? _191 : rx_state;
    assign _244 = _199 ? _156 : rx_state;
    assign _246 = _164 ? _245 : _244;
    assign _201 = rx_byte_cnt + _200;
    assign _202 = _199 ? _201 : rx_byte_cnt;
    assign _193 = rx_state == _156;
    assign _203 = _193 ? _202 : rx_byte_cnt;
    assign _192 = rx_state == _191;
    assign _205 = _192 ? _204 : _203;
    assign _13 = _205;
    always @(posedge _31) begin
        if (_41)
            rx_byte_cnt <= _195;
        else
            rx_byte_cnt <= _13;
    end
    assign _240 = rx_byte_cnt == _239;
    assign _241 = _240 ? _220 : rx_state;
    assign _242 = _199 ? _241 : rx_state;
    assign _198 = _16 == _197;
    assign _230 = _15 == _229;
    assign _231 = _230 ? vdd : _161;
    assign _15 = usb_uart_rx;
    assign _225 = _15 == _224;
    assign _226 = _225 ? gnd : _161;
    assign _41 = ~ _40;
    assign _211 = _16 + _210;
    assign _208 = _16 == _207;
    assign _206 = ~ _161;
    assign _209 = _206 | _208;
    assign _213 = _209 ? _212 : _211;
    always @(posedge _31) begin
        if (_41)
            _216 <= _215;
        else
            _216 <= _213;
    end
    assign _16 = _216;
    assign _163 = _16 == _162;
    assign _164 = _161 & _163;
    assign _227 = _164 ? _226 : _161;
    assign _222 = _199 ? gnd : _161;
    assign _221 = rx_state == _220;
    assign _223 = _221 ? _222 : _161;
    assign _219 = rx_state == _218;
    assign _228 = _219 ? _227 : _223;
    assign _217 = rx_state == _191;
    assign _232 = _217 ? _231 : _228;
    assign _17 = _232;
    always @(posedge _31) begin
        if (_41)
            _161 <= _160;
        else
            _161 <= _17;
    end
    assign _199 = _161 & _198;
    assign _237 = _199 ? _191 : rx_state;
    assign _236 = rx_state == _220;
    assign _238 = _236 ? _237 : rx_state;
    assign _235 = rx_state == _156;
    assign _243 = _235 ? _242 : _238;
    assign _234 = rx_state == _218;
    assign _247 = _234 ? _246 : _243;
    assign _233 = rx_state == _191;
    assign _249 = _233 ? _248 : _247;
    assign _18 = _249;
    always @(posedge _31) begin
        if (_41)
            rx_state <= _154;
        else
            rx_state <= _18;
    end
    assign _250 = rx_state == _220;
    assign _253 = _250 ? _252 : gnd;
    assign _19 = _253;
    assign _20 = _19;
    always @(posedge _82) begin
        _85 <= _33;
    end
    always @(posedge _82) begin
        _88 <= _85;
    end
    assign _82 = _30[2:2];
    assign _33 = _30[0:0];
    always @(posedge _31) begin
        _37 <= _33;
    end
    always @(posedge _31) begin
        _40 <= _37;
    end
    assign _22 = reset;
    assign _24 = sys_clock;
    design_1_clk_wiz_0_0
        the_design_1_clk_wiz_0_0
        ( .clk_in1(_24), .resetn(_22), .clk_out3(_30[3:3]), .clk_out2(_30[2:2]), .clk_out1(_30[1:1]), .locked(_30[0:0]) );
    assign _31 = _30[1:1];
    user_application
        user_application
        ( .clk_166(_31), .clear_n_166(_40), .clk_200(_82), .clear_n_200(_88), .uart_rx_valid(_20), .uart_rx_value(_12), .eth_clk_rx(_89), .eth_rx_axis_mac_tdata(_90), .eth_rx_axis_mac_tlast(_91), .eth_rx_axis_mac_tuser(_92), .eth_rx_axis_mac_tvalid(_93), .eth_clk_tx(_94), .eth_tx_tready(_95), .eth_tx_axis_mac_tvalid(_97[35:35]), .eth_tx_axis_mac_tuser(_97[34:34]), .eth_tx_axis_mac_tlast(_97[33:33]), .eth_tx_axis_mac_tdata(_97[32:25]), .uart_tx_value(_97[24:17]), .uart_tx_valid(_97[16:16]), .led_rgb_b3(_97[15:15]), .led_rgb_g3(_97[14:14]), .led_rgb_r3(_97[13:13]), .led_rgb_b2(_97[12:12]), .led_rgb_g2(_97[11:11]), .led_rgb_r2(_97[10:10]), .led_rgb_b1(_97[9:9]), .led_rgb_g1(_97[8:8]), .led_rgb_r1(_97[7:7]), .led_rgb_b0(_97[6:6]), .led_rgb_g0(_97[5:5]), .led_rgb_r0(_97[4:4]), .led_4bits(_97[3:0]) );
    assign _254 = _97[3:0];

    /* aliases */

    /* output assignments */
    assign led_4bits = _254;
    assign led_rgb = _152;
    assign usb_uart_tx = _8;
    assign eth_mii_tx_en = _28;
    assign eth_mii_txd = _27;
    assign mdc = _26;

endmodule
