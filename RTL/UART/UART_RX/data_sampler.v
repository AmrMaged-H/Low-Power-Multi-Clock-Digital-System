`include "CONFIG_MACROS.v"

module data_sampler (input wire CLK,
                     input wire RST,
                     input wire data_sample_en,
                     input wire RX_IN,

                     output reg sampled_bit);
    
    reg [2:0] Samples_Reg;
    wire sampled_bit_comb;

    always @(posedge CLK or negedge RST) begin
        if(!RST)
            Samples_Reg <= 3'd0;
        else if (data_sample_en)
            Samples_Reg <= {Samples_Reg, RX_IN };
    end

    assign sampled_bit_comb = (Samples_Reg[0] & Samples_Reg[1]) || (Samples_Reg[0] & Samples_Reg[2]) || (Samples_Reg[1] & Samples_Reg[2]);

    always @(posedge CLK or negedge RST) begin
        if (!RST)
            sampled_bit <= 1'd0;
        else
            sampled_bit <= sampled_bit_comb;
    end
    
endmodule
