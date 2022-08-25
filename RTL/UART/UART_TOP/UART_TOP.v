`include "CONFIG_MACROS.v"

module UART_TOP (input wire RST,
                 input wire TX_CLK,
                 input wire RX_CLK,
                 input wire RX_IN_S,
                 output wire [`WIDTH-1:0] RX_OUT_P,
                 output wire RX_OUT_V,
                 input wire [`WIDTH-1:0] TX_IN_P,
                 input wire TX_IN_V,
                 output wire TX_OUT_S,
                 output wire TX_OUT_V,
                 input wire [4:0] Prescale,
                 input wire parity_enable,
                 input wire parity_type);
    
    UART_RX RX_Module (
    .CLK(RX_CLK),
    .RST(RST),
    .RX_IN(RX_IN_S),
    .PAR_EN(parity_enable),
    .PAR_TYP(parity_type),
    .Prescale(Prescale),
    
    .Data_Valid(RX_OUT_V),
    .P_DATA(RX_OUT_P)
    );

    UART_TX TX_Module (
    .Data_Valid(TX_IN_V),
    .CLK(TX_CLK),
    .parity_enable(parity_enable),
    .P_DATA(TX_IN_P),
    .RST(RST),
    .parity_type(parity_type),
    .busy(TX_OUT_V),
    .TX_OUT(TX_OUT_S)
    );
    
endmodule
    
