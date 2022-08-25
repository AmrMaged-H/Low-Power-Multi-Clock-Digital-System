`include "CONFIG_MACROS.v"

module edge_bit_counter (input wire CLK,
                         input wire RST,
                         input wire edge_count_en,
                         input wire StartTransition,
                         input wire [4:0] Prescale,

                         output reg [`BIT_COUNTER_WIDTH-1:0] bit_cnt,
                         output reg [4:0] edge_cnt
                         );

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            bit_cnt <= 'd0;
            edge_cnt <= 'd0;
        end
        else if (!edge_count_en) begin
            bit_cnt <= 'd0;
            edge_cnt <= 'd0;
        end
        else if (StartTransition && edge_cnt == Prescale - 2) begin
            bit_cnt <= bit_cnt + 'd1;
            edge_cnt <= 'd0;        
        end
        else if (edge_cnt == Prescale - 1) begin
            bit_cnt <= bit_cnt + 'd1;
            edge_cnt <= 'd0;        
        end
        else
            edge_cnt <= edge_cnt + 'd1;        
    end
    
endmodule
