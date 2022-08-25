/*
 
 Module Name : RX_CTRL
 
 Functionality:
 The RX Controller is a FSM Which Is Supposed to Receive The Parallel Data From The
 UART RX Module, Extracts The Command And Controls The Other Blocks
 
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

module RX_CTRL (input wire CLK,
                input wire RST,
                input wire [`WIDTH-1:0] RX_P_DATA,
                input wire RX_D_VALID,
                input wire OUT_Valid,

                output reg CLK_EN,
                output reg ALU_EN,                 
                output reg [3:0] ALU_FUN,          
                output reg [`ADDR_WIDTH-1:0] Addr, 
                output reg WrEn,                   
                output reg RdEn,                   
                output wire [`WIDTH-1:0] WrData);  
    
    //////////////////////////////////////////////// States Registers ////////////////////////////////////////////////
    
    reg [2:0] PS, NS;
    
    localparam IDLE            = 3'd0;
    localparam Receive_Wr_Addr = 3'd1;
    localparam Receive_Wr_Data = 3'd2;
    localparam Receive_Rd_Addr = 3'd3;
    localparam OPR_A_Write     = 3'd4;
    localparam OPR_B_Write     = 3'd5;
    localparam ALU_FUN_Rd      = 3'd6;
    localparam ALU_Exc         = 3'd7;
    
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            PS <= IDLE;
        else
            PS <= NS;
    end
    
    //////////////////////////////////////////////// Next State Logic ////////////////////////////////////////////////
    
    always @(*) begin
        case (PS)
            IDLE : begin
                if (RX_D_VALID) begin
                    case (RX_P_DATA)
                        'hAA:    NS = Receive_Wr_Addr;
                        'hBB:    NS = Receive_Rd_Addr;
                        'hCC:    NS = OPR_A_Write;
                        'hDD:    NS = ALU_FUN_Rd;
                        default: NS = IDLE;
                    endcase
                end
                else
                    NS = IDLE;
            end
            
            Receive_Wr_Addr : begin
                if (RX_D_VALID)
                    NS = Receive_Wr_Data;
                else
                    NS = Receive_Wr_Addr;
            end
            
            Receive_Wr_Data : begin
                if (RX_D_VALID)
                    NS = IDLE;
                else
                    NS = Receive_Wr_Data;
            end
            
            Receive_Rd_Addr : begin
                if (RX_D_VALID)
                    NS = IDLE;
                else
                    NS = Receive_Rd_Addr;
            end
            
            OPR_A_Write : begin
                if (RX_D_VALID)
                    NS = OPR_B_Write;
                else
                    NS = OPR_A_Write;
            end
            
            OPR_B_Write : begin
                if (RX_D_VALID)
                    NS = ALU_FUN_Rd;
                else
                    NS = OPR_B_Write;
            end
            
            ALU_FUN_Rd : begin
                if (RX_D_VALID)
                    NS = ALU_Exc;
                else
                    NS = ALU_FUN_Rd;
            end
            
            ALU_Exc : begin
                if (OUT_Valid)
                    NS = IDLE;
                else
                    NS = ALU_Exc;
            end
            
            default: NS = IDLE;
            
        endcase
    end
    
    ////////////////////////////////////////////////// Address Reg. //////////////////////////////////////////////////
    
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            Addr <= 'd0;
        else if ((PS == Receive_Wr_Addr || PS == Receive_Rd_Addr) && RX_D_VALID)
            Addr <= RX_P_DATA;
        else if ((PS == OPR_A_Write) && RX_D_VALID)
            Addr <= 'd0;
        else if ((PS == OPR_B_Write) && RX_D_VALID)
            Addr <= 'd1;
    end
        
    ////////////////////////////////////////////////// Write Enable //////////////////////////////////////////////////
    
    // The Flag Should be Set After Receiving Operand A, B OR After Receiving The Data To Be
    // Written In The Case Of The Register File Write Command
    
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            WrEn <= 'd0;
        else if ((PS == OPR_A_Write || PS == OPR_B_Write) && RX_D_VALID)
            WrEn <= 'd1;
        else if ((PS == Receive_Wr_Data) && RX_D_VALID)
            WrEn <= 'd1;
        else
            WrEn <= 'd0;
    end
        
    ////////////////////////////////////////////////// Read Enable ///////////////////////////////////////////////////
    
    // The Flag Should be Set After Receiving The Register Address To Be Read
    
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            RdEn <= 'd0;
        else if ((PS == Receive_Rd_Addr) && RX_D_VALID)
            RdEn <= 'd1;
        else
            RdEn <= 'd0;
    end
        
    //////////////////////////////////////////////// Write Data Bus //////////////////////////////////////////////////
    
    // The Bus Should Be Simply Updated With The Received Parallel data
    // Where The Write Operation is COntrolled Via The WrEn Flag
    
    assign WrData = RX_P_DATA;
        
    ////////////////////////////////////////////// ALU_FUN and ALU_EN ////////////////////////////////////////////////
    
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            ALU_FUN <= 'd0;
            ALU_EN  <= 1'b0;
        end
        else if ((PS == ALU_FUN_Rd) && RX_D_VALID) begin
            ALU_FUN <= RX_P_DATA [3:0];
            ALU_EN  <= 1'b1;
        end
        else if (PS == ALU_Exc) 
            ALU_EN  <= 1'b0;
    end
                
    //////////////////////////////////////////////// Clock Enable ////////////////////////////////////////////////////
    
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            CLK_EN <= 1'b0;
        else if ((PS == ALU_FUN_Rd) && RX_D_VALID)
            CLK_EN <= 1'b1;
        else if ((PS == ALU_Exc) && OUT_Valid)
            CLK_EN <= 1'b0;
    end
                    
endmodule
