`include "CONFIG_MACROS.v"

module parity_check (input wire CLK,
                     input wire RST,
                     input wire par_chk_en,
                     input wire PAR_TYP,
                     input wire sampled_bit,
                     input wire PAR_EN,
                     input wire [`WIDTH-1:0] P_DATA,
                     output reg par_err);
    
    always @(posedge CLK or negedge RST) begin

        if (!RST)
            par_err <= 1'b0;

        else if (!PAR_EN)
            par_err <= 1'b0;

        else if (par_chk_en) begin

            if (PAR_TYP == `ODD_PARITY_CONFIG) begin
                if ( (~^P_DATA) == sampled_bit )
                    par_err <= 1'b0;
                else
                    par_err <= 1'b1;
            end
            else begin
                if ( (^P_DATA) == sampled_bit )
                    par_err <= 1'b0;
                else
                    par_err <= 1'b1;
            end

        end
    end

endmodule
