/*
 Module Name : TX_CTRL
 
 Functionality:
 The Module Is Responsible for Sending The Received Command Result
 After Finishing The Operation Whatever it is.
 
 The Two Controllers Are Needed As The UART IS Full-Duplex, So We may Need
 To Send_ALUOut2 The Previous Result While Receiving a New Command.
 
 Supported Commands :
 1) Register File Write
 Frame 0: 0xAA Write Command
 Frame 1: Write Address (Default : 4 Bits)
 Frame 2: data
 
 2) Register File Read
 Frame 0: 0xBB read Command
 Frame 1: Read Address (Default : 4 Bits)
 --> The Time Out Option May Be Handeled In The Future
 
 3) ALU Operation command with operand (4 frames)
 Frame 0: 0xCC --> ALU OPR With Operand
 Frame 1: Operand A
 Frame 2: Operand B
 Frame 3: ALU Fun. (Enable Clock Gating Upon Writing B)
 --> We Need To Write The Operands Before Enabling The ALU
 
 4) ALU Operation command with No operand (2 frames)
 Frame 0: 0xDD --> ALU OPR With No Operand
 Frame 1: ALU Fun.
 --> Note : OPR A Has Address 0x0 and OPR B is 0x1
 */

`include "CONFIG_MACROS.v"

module TX_CTRL (input wire CLK,
                input wire RST,
                input wire OUT_Valid,
                input wire RX_D_VALID,
                input wire RdData_Valid,
                input wire Busy,
                input wire [`WIDTH-1:0] RdData,
                input wire [`WIDTH-1:0] RX_P_DATA,
                input wire [`ALU_OUT_WIDTH-1:0] ALU_OUT,
                output reg [`WIDTH-1:0] TX_P_Data,
                output reg TX_D_VALID,
                output wire clk_div_en);
    
    
    //////////////////////////////////////////////// States Registers ////////////////////////////////////////////////
    
    reg [1:0] PS, NS;
    
    localparam IDLE          = 2'd0;
    localparam Send_RdResult = 2'd1;
    localparam Send_ALUOut1  = 2'd2;
    localparam Send_ALUOut2  = 2'd3;
    
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            PS <= IDLE;
        else
            PS <= NS;
    end
    
    ////////////////////////////////////////// Next State And Output Logic ///////////////////////////////////////////
    always @(*) begin
        case (PS)
            IDLE : begin
                if (RX_D_VALID) begin
                    case (RX_P_DATA)
                        'hBB:    NS = Send_RdResult;
                        'hCC:    NS = Send_ALUOut1;
                        'hDD:    NS = Send_ALUOut1;
                        default: NS = IDLE;
                    endcase
                end
                else
                NS = IDLE;
            end
            
            Send_RdResult : begin
                if (RdData_Valid && !Busy) begin
                    NS = IDLE;
                end
                else
                NS = Send_RdResult;
            end
            
            Send_ALUOut1 : begin
                if (Busy) begin
                    NS = Send_ALUOut2;
                end
                else
                    NS = Send_ALUOut1;
            end
            
            Send_ALUOut2 : begin
                if (!Busy) begin
                    NS              = IDLE;
                end
                else
                    NS = Send_ALUOut2;
            end
            default: NS = IDLE;
        endcase
    end
    
    // We Need To Store The ALU Result As it Will Be Sent Using Two Frames
    reg [`ALU_OUT_WIDTH-1:0] ALU_OUT_Stored;
    
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            ALU_OUT_Stored <= 'd0;
        else if ((PS == Send_ALUOut1) && OUT_Valid)
            ALU_OUT_Stored <= ALU_OUT;
            end
        
    /////////////////////////////////////////////////// TX_D_VALID ////////////////////////////////////////////////////
    
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            TX_D_VALID <= 'b0;
        else if (((PS == Send_ALUOut1 && OUT_Valid) || (PS == Send_RdResult && RdData_Valid) || (PS == Send_ALUOut2)) && !Busy)
            TX_D_VALID <= 1'b1;
        else if (Busy)
            TX_D_VALID <= 1'b0;
    end
            
    /////////////////////////////////////////////////// TX_P_DATA ////////////////////////////////////////////////////
    
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            TX_P_Data <= 'd0;
        else if ((PS == Send_RdResult) && RdData_Valid && !Busy)
            TX_P_Data <= RdData;
        else if ((PS == Send_ALUOut1) && OUT_Valid && !Busy)
            TX_P_Data <= ALU_OUT [7:0];
        else if ((PS == Send_ALUOut2) && !Busy)
            TX_P_Data <= ALU_OUT_Stored [15:8] ;
    end
                        
    assign clk_div_en = 1'b1;

endmodule
