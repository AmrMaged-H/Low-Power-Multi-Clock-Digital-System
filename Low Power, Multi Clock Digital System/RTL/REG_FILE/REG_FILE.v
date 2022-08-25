/*
 Module Name : Reg_File
 
 Functionality:
 
 The Register File Represents a Group of Registers Which We Can Write In Or
 Read From, Where The Required Reg IS Selected Depending in the Addr line of
 the module.
 
 The Read and Write Operations are Controlled Via The Write And Read Enable Flags.
 
 Our Register File has Reserved Registers From 0x0 To 0x3
 Where 0x0 and 0x1 Are Reserved For the Operands A and B
 While 0x2 and 0x3 Are Reserved For :
 0x2 --> UART Config
 REG2[0]    : Parity Enable
 REG2[1]    : Parity Type
 REG2[6:2]  : Prescale
 
 0x3 --> Div Ratio
 REG3[0:3]  : Division Ratio
 REG3[7:4]  : Not Used
 */

`include "CONFIG_MACROS.v"

module REG_FILE (input wire CLK,
                 input wire RST,
                 input wire [`WIDTH-1:0] WrData,       // Write Data Bus
                 input wire [`ADDR_WIDTH-1:0] Address, // Address Bus
                 input wire WrEn,                      // Active High
                 input wire RdEn,                      // Active High
                 output reg RdData_Valid,
                 output reg [`WIDTH-1:0] RdData,
                 output wire [`WIDTH-1:0] REG0,
                 output wire [`WIDTH-1:0] REG1,
                 output wire [`WIDTH-1:0] REG2,
                 output wire [`WIDTH-1:0] REG3);
    
    
    // Registers Representation
    reg [`WIDTH-1:0] REG [0:`REG_FILE_DEPTH-1];
    
    integer i; // To Be Used In The Reset For Loop
    
    always @(posedge CLK or negedge RST) begin
        
        if (!RST) begin
            
            REG [0]      <= 'd0;
            REG [1]      <= 'd0;
            REG [2]      <= 'b001000_01;
            REG [3]      <= 'b0000_1000;
            RdData       <= 'd0;
            RdData_Valid <= 1'b0;
            
            for (i = 4 ; i < `REG_FILE_DEPTH ; i = i+1) begin
                REG [i] <= 'd0;
            end
            
        end
        
        else if ((WrEn == 1'b1) && (RdEn == 1'b0)) 
            REG [Address] <= WrData;

        else if ((WrEn == 1'b0) && (RdEn == 1'b1)) begin
            RdData       <= REG [Address];
            RdData_Valid <= 1'b1;
        end

        else
            RdData_Valid <= 1'b0;
    
    end

    assign REG0 = REG[0] ;
    assign REG1 = REG[1] ;
    assign REG2 = REG[2] ;
    assign REG3 = REG[3] ;
    
endmodule
