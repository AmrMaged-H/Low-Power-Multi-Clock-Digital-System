// Data Width Parameter
`define WIDTH 8

// The Bit Counter Width (Used In The UART_RX Module)
`define BIT_COUNTER_WIDTH 4

// Parity Parameters
`define ODD_PARITY_CONFIG 1 // 0 or 1
`define EVEN_PARITY_CONFIG 0 // 0 or 1

// Clock Divider Parameters
`define CLK_DIV_WIDTH 4

// Register File Parameters
`define ADDR_WIDTH 4
`define REG_FILE_DEPTH 16

// ALU Parameters
`define ALU_OUT_WIDTH 16
`define ALU_FUN_WIDTH 4 

// Synchronizers Parameters
`define DATA_SYNC_STAGES 2
`define RST_SYNC_STAGES 2