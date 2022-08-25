/*

Module Name : RST_SYNC

Functionality :


*/
`include "CONFIG_MACROS.v"
module RST_SYNC (input wire CLK,        // Dest. Clock
                 input wire RST,
                 output wire SYNC_RST);
    
    reg [`RST_SYNC_STAGES-1 : 0] STAGES;
    
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            STAGES <= 'd0;
        else
            STAGES <= { 1'b1, STAGES [`RST_SYNC_STAGES-1 : 1] };
    end
    
    assign SYNC_RST = STAGES [0];
    
endmodule
