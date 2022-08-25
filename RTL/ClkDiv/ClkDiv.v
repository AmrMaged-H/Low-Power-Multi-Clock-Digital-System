/*

Module Name: ClkDiv

Functionality:

    - The Clock Divider is used to divide the input clock by a specific value
      being determined via the i_div_ratio input

    - When The i_clk_en is low, the reference clock should be passed as the
      output clock

 */

`include "CONFIG_MACROS.v"

module ClkDiv (input wire i_ref_clk,
               input wire i_rst_n,
               input wire i_clk_en,
               input wire [`CLK_DIV_WIDTH-1:0] i_div_ratio,

               output reg o_div_clk);
    
    reg [`CLK_DIV_WIDTH-1:0] CyclesCount;
    reg ToggleFlag;
    reg ClkInt;

    always @(posedge i_ref_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            ClkInt <= 1'b0;
        else if (ToggleFlag)
            ClkInt <= ~ ClkInt;
    end

    always @(*) begin
        if (!i_clk_en && i_rst_n)
            o_div_clk = i_ref_clk;
        else
            o_div_clk = ClkInt;
    end
    
    always @(posedge i_ref_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            CyclesCount <= 'd0;
        else if (CyclesCount != (i_div_ratio-1))
            CyclesCount <= CyclesCount + 1'b1;
        else 
            CyclesCount <= 'd0;
    end

    always @(*) begin
        
            if (( (CyclesCount == (i_div_ratio - 1) ) || (CyclesCount == (i_div_ratio >> 1) -1) ) && i_rst_n)
                ToggleFlag = 1'b1;
            else 
                ToggleFlag = 1'b0;
    end    

endmodule
