module module_name#(
    parameter A = 1

) (
    input      i_clk,
    output reg o_test
);
wire s_a [20:0];

wire s_1;
wire s_2;
wire s_3;
wire s_4;
wire s_5;
wire s_6;
wire s_7;
wire s_8;
wire s_9;
wire s_10;
wire s_11;
wire s_12;
wire s_13;
wire s_14;
wire s_15;
wire s_16;
wire s_17;
wire s_18;
wire s_19;
wire s_20;
wire s_21;

genvar i;
generate
for (i = 0; i < 10; i = i + 1)
begin : gen_loop
    test uut (
        .i_1  (s_1  ),
        .i_2  (s_2  ),
        .i_3  (s_3  ),
        .i_4  (s_4  ),
        .i_5  (s_5  ),
        .i_6  (s_6  ),
        .i_7  (s_7  ),
        .i_8  (s_8  ),
        .i_9  (s_9  ),
        .i_10 (s_10 ),
        .i_11 (s_11 ),
        .i_12 (s_12 ),
        .i_13 (s_13 ),
        .i_14 (s_14 ),
        .i_15 (s_15 ),
        .i_16 (s_16 ),
        .i_17 (s_17 ),
        .i_18 (s_18 ),
        .i_19 (s_19 ),
        .i_20 (s_20 ),
        .i_21 (s_21 )
    );
end
endgenerate

always @(posedge i_clk) begin
    if (s_1) begin
        s_a[0]  <= s_1;
        s_a[1]  <= s_2;
        s_a[2]  <= s_3;
        s_a[3]  <= s_4;
        s_a[4]  <= s_5;
        s_a[5]  <= s_6;
        s_a[6]  <= s_7;
        s_a[7]  <= s_8;
        s_a[8]  <= s_9;
        s_a[9]  <= s_10;
        s_a[10] <= s_11;
        s_a[11] <= s_12;
        s_a[12] <= s_13;
        s_a[13] <= s_14;
        s_a[14] <= s_15;
        s_a[15] <= s_16;
        s_a[16] <= s_17;
        s_a[17] <= s_18;
        s_a[18] <= s_19;
        s_a[19] <= s_20;
        s_a[20] <= s_21;
    end
    else begin
        o_test <= s_a[20];
    end
end

endmodule
