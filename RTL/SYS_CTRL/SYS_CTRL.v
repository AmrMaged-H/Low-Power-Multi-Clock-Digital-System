`include "CONFIG_MACROS.v"

module SYS_CTRL (input wire CLK_c,
                 input wire RST_c,
                 input wire BUSY,
                 input wire [`ALU_OUT_WIDTH-1:0] ALU_Out,
                 input wire OUT_VALID,
                 input wire [`WIDTH-1:0] RX_P_Data,
                 input wire RX_D_Valid,
                 input wire [`WIDTH-1:0] Rd_Data,
                 input wire Rd_Data_Valid,
                 output wire ALU_En,
                 output wire [3:0] ALU_Fun,
                 output wire CLK_En,
                 output wire [`ADDR_WIDTH-1:0] Address,
                 output wire Wr_En,
                 output wire Rd_En,
                 output wire [`WIDTH-1:0] Wr_Data,
                 output wire [`WIDTH-1:0] TX_P_DATA,
                 output wire TX_D_Valid,
                 output wire Clk_Div_En);
    
    
    TX_CTRL TX_CTRL_Mod (
    .CLK(CLK_c),
    .RST(RST_c),
    .OUT_Valid(OUT_VALID),
    .RX_D_VALID(RX_D_Valid),
    .RdData_Valid(Rd_Data_Valid),
    .Busy(BUSY),
    .RdData(Rd_Data),
    .RX_P_DATA(RX_P_Data),
    .ALU_OUT(ALU_Out),
    
    .TX_P_Data(TX_P_DATA),
    .TX_D_VALID(TX_D_Valid),
    .clk_div_en(Clk_Div_En));
    
    RX_CTRL RX_CTRL_Mod(
    .CLK(CLK_c),
    .RST(RST_c),
    .RX_P_DATA(RX_P_Data),
    .RX_D_VALID(RX_D_Valid),
    .OUT_Valid(OUT_VALID),
    
    .CLK_EN(CLK_En),
    .ALU_EN(ALU_En),
    .ALU_FUN(ALU_Fun),
    .Addr(Address),
    .WrEn(Wr_En),
    .RdEn(Rd_En),
    .WrData(Wr_Data));
    
endmodule
