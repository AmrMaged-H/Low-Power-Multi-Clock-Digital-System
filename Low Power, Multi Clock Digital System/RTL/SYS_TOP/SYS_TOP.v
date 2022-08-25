`include "CONFIG_MACROS.v"


module SYS_TOP (input wire RST_N,
                input wire UART_CLK,
                input wire REF_CLK,
                input wire UART_RX_IN,
                output wire UART_TX_O);
    
    //////////////////////////////////////// Internal Signals ////////////////////////////////////////
    wire SYNC_REF_RST;
    wire SYNC_UART_RST;
    
    wire UART_RX_VALID_INT;
    wire [`WIDTH-1:0] UART_BUS_OUT;
    wire [`WIDTH-1:0] SYNC_BUS_RX;
    wire SYNC_UART_RX_V;
    
    wire UART_TX_CLK;
    wire UART_TX_VALID;
    wire [`WIDTH-1:0] UART_TX_IN;
    wire [`WIDTH-1:0] UART_TX_SYN;
    wire UART_TX_VALID_SYN;
    
    wire UART_TX_Busy;
    wire UART_TX_Busy_SYNC;
    
    wire ClockDiv_En;
    wire [`WIDTH-1:0] DIV_RATIO;
    
    wire [`WIDTH-1:0] UART_CONFIG;
    
    wire [`WIDTH-1:0] RF_WrData;
    wire [`WIDTH-1:0] RF_RdData;
    wire RF_RdData_Valid;
    wire [`WIDTH-1:0] OPRA;
    wire [`WIDTH-1:0] OPRB;
    wire RF_WrEn, RF_RdEn;
    wire [`ADDR_WIDTH-1:0] RF_ADDR;
    
    wire ALU_CLK;
    wire ALU_EN_INT;
    wire [3:0] ALU_FUN_INT;
    wire [`ALU_OUT_WIDTH-1:0] ALU_OUT_INT;
    wire ALU_Valid;
    
    wire CLKG_EN;
    /////////////////////////////////////// Reset Synchonizers ///////////////////////////////////////
    
    RST_SYNC REF_RST_SYNC(
    .CLK(REF_CLK),        // Dest. Clock
    .RST(RST_N),
    .SYNC_RST(SYNC_REF_RST));
    
    RST_SYNC UART_RST_SYNC(
    .CLK(UART_CLK),        // Dest. Clock
    .RST(RST_N),
    .SYNC_RST(SYNC_UART_RST));
    
    //////////////////////////////////////// Data Synchonizers ///////////////////////////////////////
    
    DATA_SYNC REF_DATA_SYNC(
    .CLK(REF_CLK),
    .RST(SYNC_REF_RST),
    .Bus_En(UART_RX_VALID_INT),
    .Bus_IN(UART_BUS_OUT),
    
    .Sync_Bus(SYNC_BUS_RX),
    .Enable_Pulse(SYNC_UART_RX_V));
    
    DATA_SYNC UART_DATA_SYNC(
    .CLK(UART_TX_CLK),
    .RST(SYNC_UART_RST),
    .Bus_En(UART_TX_VALID),
    .Bus_IN(UART_TX_IN),
    
    .Sync_Bus(UART_TX_SYN),
    .Enable_Pulse(UART_TX_VALID_SYN));
    
    ///////////////////////////////////////// Bit Synchonizer ////////////////////////////////////////
    
    BIT_SYNC  U0_bit_sync (
    .dest_clk(REF_CLK),
    .dest_rst(SYNC_REF_RST),
    .unsync_bit(UART_TX_Busy),
    .sync_bit(UART_TX_Busy_SYNC)
    );
    
    ////////////////////////////////////////// Clock Divider /////////////////////////////////////////
    ClkDiv U0_ClkDiv (
    .i_ref_clk(UART_CLK),
    .i_rst_n(SYNC_UART_RST),
    .i_clk_en(ClockDiv_En),
    .i_div_ratio(DIV_RATIO [3:0]),
    
    .o_div_clk(UART_TX_CLK));
    
    /////////////////////////////////////////////// UART /////////////////////////////////////////////
    
    UART_TOP UART_Mod (
    .RST(SYNC_UART_RST),
    .TX_CLK(UART_TX_CLK),
    .RX_CLK(UART_CLK),
    .RX_IN_S(UART_RX_IN),
    .RX_OUT_P(UART_BUS_OUT),
    .RX_OUT_V(UART_RX_VALID_INT),
    .TX_IN_P(UART_TX_SYN),
    .TX_IN_V(UART_TX_VALID_SYN),
    .TX_OUT_S(UART_TX_O),
    .TX_OUT_V(UART_TX_Busy),
    .Prescale(UART_CONFIG[6:2]),
    .parity_enable(UART_CONFIG[0]),
    .parity_type(UART_CONFIG[1]));
    
    ////////////////////////////////////////// Register File /////////////////////////////////////////
    REG_FILE RegFile_Module (
    .CLK(REF_CLK),
    .RST(SYNC_REF_RST),
    .WrData(RF_WrData),                  // Write Data Bus
    .Address(RF_ADDR),                   // Address Bus
    .WrEn(RF_WrEn),                      // Active High
    .RdEn(RF_RdEn),                      // Active High
    .RdData_Valid(RF_RdData_Valid),
    .RdData(RF_RdData),
    .REG0(OPRA),
    .REG1(OPRB),
    .REG2(UART_CONFIG),
    .REG3(DIV_RATIO));
    
    /////////////////////////////////////////////// ALU /////////////////////////////////////////////
    ALU ALU_Module (
    .CLK(ALU_CLK),
    .RST(SYNC_REF_RST),
    .En(ALU_EN_INT),
    .A(OPRA),
    .B(OPRB),
    .ALU_FUN(ALU_FUN_INT),
    .ALU_OUT(ALU_OUT_INT),
    .OUT_Valid(ALU_Valid));
    
    /////////////////////////////////////////// Clock Gating //////////////////////////////////////////
    
    CLK_GATE U0_CLK_GATE (
    .CLK_EN(CLKG_EN),
    .CLK(REF_CLK),
    .GATED_CLK(ALU_CLK)
    );
    
    ///////////////////////////////////////////// SYS CTRL ///////////////////////////////////////////
    
    SYS_CTRL CTRL_Mod (
    .CLK_c(REF_CLK),
    .RST_c(SYNC_REF_RST),   
    .BUSY(UART_TX_Busy_SYNC),
    .ALU_Out(ALU_OUT_INT),
    .OUT_VALID(ALU_Valid),
    .RX_P_Data(SYNC_BUS_RX),
    .RX_D_Valid(SYNC_UART_RX_V),
    .Rd_Data(RF_RdData),
    .Rd_Data_Valid(RF_RdData_Valid),
    .ALU_En(ALU_EN_INT),
    .ALU_Fun(ALU_FUN_INT),
    .CLK_En(CLKG_EN),
    .Address(RF_ADDR),
    .Wr_En(RF_WrEn),
    .Rd_En(RF_RdEn),
    .Wr_Data(RF_WrData),
    .TX_P_DATA(UART_TX_IN),
    .TX_D_Valid(UART_TX_VALID),
    .Clk_Div_En(ClockDiv_En));
endmodule
    
