`include "CONFIG_MACROS.v"

module deserializer (input wire deser_en,
                     input wire sampled_bit,
                     input wire CLK,
                     input wire RST,
                     output reg [`WIDTH-1:0] P_DATA);
        
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            P_DATA <= 'd0;
        else if (deser_en)
            P_DATA <= { sampled_bit, P_DATA [`WIDTH-1:1] };
    end
            
endmodule
