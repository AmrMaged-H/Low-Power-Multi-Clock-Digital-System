/*
 
 Module Name : ALU (Standing For : Arithmetic Logic Unit)
 
 Functionality :
 The Module Is Responsible For Performing Aritmetic Or Logical
 Operations On The Operands A and B And Return The Result.
 
 */

`include "CONFIG_MACROS.v"

module ALU (input wire CLK,
            input wire RST,
            input wire En,
            input wire [`WIDTH-1:0] A,
            input wire [`WIDTH-1:0] B,
            input wire [`ALU_FUN_WIDTH-1:0] ALU_FUN,
            output reg [`ALU_OUT_WIDTH-1:0] ALU_OUT,
            output reg OUT_Valid);
    
    reg [`ALU_OUT_WIDTH-1:0] ALU_OUT_Comb;
    reg OUT_Valid_Comb;
    
    always @(posedge CLK or negedge RST)
    begin
        if (!RST)
        begin
            ALU_OUT   <= 'b0 ;
            OUT_Valid <= 1'b0 ;
        end
        else
        begin
            ALU_OUT   <= ALU_OUT_Comb ;
            OUT_Valid <= OUT_Valid_Comb ;
        end
    end
    
    always @(*)
    begin    
        if (En) begin
            
            OUT_Valid_Comb = 1'b1;
            
            case (ALU_FUN)
                4'd0:   ALU_OUT_Comb = A + B;
                4'd1:   ALU_OUT_Comb = A - B;
                4'd2:   ALU_OUT_Comb = A * B;
                4'd3:   ALU_OUT_Comb = A / B;
                4'd4:   ALU_OUT_Comb = A & B;
                4'd5:   ALU_OUT_Comb = A | B;
                4'd6:   ALU_OUT_Comb = ~ (A & B);
                4'd7:   ALU_OUT_Comb = ~ (A | B);
                4'd8:   ALU_OUT_Comb = A ^ B;
                4'd9:   ALU_OUT_Comb = ~ (A ^ B);
                
                4'd10:	begin
                    if (A == B)
                        ALU_OUT_Comb = 4'd1;
                    else
                        ALU_OUT_Comb = 4'd0;
                end
                
                4'd11:	begin
                    if (A > B)
                        ALU_OUT_Comb = 4'd2;
                    else
                        ALU_OUT_Comb = 4'd0;
                end
                
                4'd12:	begin
                    if (A < B)
                        ALU_OUT_Comb = 4'd3;
                    else
                        ALU_OUT_Comb = 4'd0;
                end
                
                4'd13:	ALU_OUT_Comb   = A>>1; // Divide A by 2
                4'd14:	ALU_OUT_Comb   = A<<1; // Multiply A by 2
                default: ALU_OUT_Comb = 4'd0;
            endcase
        end
        else begin
            OUT_Valid_Comb = 1'b0;
            ALU_OUT_Comb = ALU_OUT;
        end
    end
    
    
    
endmodule
