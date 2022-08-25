
`include "CONFIG_MACROS.v"

module SYS_TB();
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////// Frames and Clocks Parameters //////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //parameters
    parameter DATA_WIDTH           = 8 ;
    parameter REF_CLK_PER          = 20 ;
    parameter UART_RX_CLK_PER      = 100 ;
    parameter WR_NUM_OF_FRAMES     = 3 ;
    parameter RD_NUM_OF_FRAMES     = 2 ;
    parameter ALU_WP_NUM_OF_FRAMES = 4 ;
    parameter ALU_NP_NUM_OF_FRAMES = 2 ;
    
    parameter WR_NUM_OF_BITS     = 33 ;
    parameter RD_NUM_OF_BITS     = 22 ;
    parameter ALU_WP_NUM_OF_BITS = 44 ;
    parameter ALU_NP_NUM_OF_BITS = 22 ;
    
    reg   [WR_NUM_OF_FRAMES*11-1:0]       WR_CMD     = 'b10_01110111_0_10_00000101_0_10_10101010_0 ;
    reg   [RD_NUM_OF_FRAMES*11-1:0]       RD_CMD     = 'b11_00000010_0_10_10111011_0    ;
    reg   [ALU_WP_NUM_OF_FRAMES*11-1:0]   ALU_WP_CMD = 'b11_00000001_0_10_00000011_0_10_00000101_0_10_11001100_0 ;
    reg   [ALU_NP_NUM_OF_FRAMES*11-1:0]   ALU_NP_CMD = 'b11_00000001_0_10_11011101_0 ;
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// Test-Bench Signals ///////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    reg                                RST_N_tb;
    reg                                UART_CLK_tb;
    reg                                REF_CLK_tb;
    reg                                UART_RX_IN_tb;
    wire                               UART_TX_O_tb;
    wire                               Data_Valid_tb;
    wire            [`WIDTH-1:0]       Rec_Data_tb;
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////// Tests ////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    initial begin
        INIT_CLK ();
        Config_RX_IN (1'b1);
        RST_And_Wait ();
        
        Test_RegFile_Read ();
        
        Test_ALU_WithOperands();

        Test_ALU_No_Operands ();
        
        #40000 $finish();
    end
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////// Tasks ////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    task Test_RegFile_Read ();
        
        begin
            $display ("\nThe Read Command Is Applied\n");
            repeat (10) @(posedge UART_CLK_tb);
            Apply_RX_Sequence (RD_CMD, RD_NUM_OF_BITS);
            $display ("Waiting For Data To Be Received");
            
            @(posedge Data_Valid_tb);
            if (Rec_Data_tb == 8'b0010_0001)
                $display ("Read Command Passed");
            else
                $display ("Read Command Failed");
        end
        
    endtask

    task Test_ALU_WithOperands ();
        
        begin
            $display ("\nThe ALU Command Is Applied\n");
            repeat (10) @(posedge UART_CLK_tb);
            Apply_RX_Sequence (ALU_WP_CMD, ALU_WP_NUM_OF_BITS);
            $display ("Waiting For Data To Be Received");
            
            @(posedge Data_Valid_tb);
            if (Rec_Data_tb == 8'b0000_0010)
                $display ("The First Byte Passed");
            else
                $display ("The First Byte Failed");

            @(posedge Data_Valid_tb);
            if (Rec_Data_tb == 8'b0000_0000)
                $display ("The Second Byte Passed");
            else
                $display ("The Second Byte Failed");
            
        end
        
    endtask

    task Test_ALU_No_Operands ();
        
        begin
            $display ("\nThe ALU Command Is Applied\n");
            repeat (10) @(posedge UART_CLK_tb);
            Apply_RX_Sequence (ALU_NP_CMD, ALU_NP_NUM_OF_BITS);
            $display ("Waiting For Data To Be Received");
            
            @(posedge Data_Valid_tb);
            if (Rec_Data_tb == 8'b0000_0010)
                $display ("The First Byte Passed");
            else
                $display ("The First Byte Failed");

            @(posedge Data_Valid_tb);
            if (Rec_Data_tb == 8'b0000_0000)
                $display ("The Second Byte Passed");
            else
                $display ("The Second Byte Failed");
            
        end
        
    endtask
    
    task INIT_CLK ();
        // No Inputs Or Outputs
        begin
            UART_CLK_tb = 1'b1;
            REF_CLK_tb  = 1'b1;
        end
    endtask
    
    task Config_RX_IN (
        input Conf_In
        );
        UART_RX_IN_tb = Conf_In;
    endtask
    
    task RST_And_Wait ();
        
        begin
            RST_N_tb                    = 1'b1;
            @(negedge UART_CLK_tb) RST_N_tb = 1'b0;
            @(negedge UART_CLK_tb) RST_N_tb = 1'b1;
            repeat (2) @(posedge UART_CLK_tb);
        end
        
    endtask
    
    task Apply_RX_Sequence (
        input [43:0] Input_Seq,
        input integer NUM_BITS
        );
        
        integer i;
        
        begin

            for (i = 0 ; i < NUM_BITS ; i = i+1) begin
                @ (posedge DUT.U0_ClkDiv.o_div_clk);
                UART_RX_IN_tb = Input_Seq [i];
            end
            
        end
        
    endtask
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////// CLK GEN. ///////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    `timescale 1ns/1ps
    
    // REF Clock Generator
    always #(REF_CLK_PER/2) REF_CLK_tb = ~REF_CLK_tb ;
    
    // UART RX Clock Generator
    always #(UART_RX_CLK_PER/2) UART_CLK_tb = ~UART_CLK_tb ;
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////// DUT Inst. //////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    SYS_TOP DUT (
    .UART_CLK(UART_CLK_tb),
    .REF_CLK(REF_CLK_tb),
    .RST_N(RST_N_tb),
    .UART_RX_IN(UART_RX_IN_tb),
    .UART_TX_O(UART_TX_O_tb)
    );
    
    
    // The UART IS Just For Testing, Where It Has Been Verified Before
    // It Will Receive The Result From The SYS_TOP And Return It To The
    // Test Bench
    
    UART_RX UART_RX_Mod (
    .CLK(UART_CLK_tb),
    .RST(RST_N_tb),
    .RX_IN(UART_TX_O_tb),
    .PAR_EN (1'b1),
    .PAR_TYP (1'b0),
    .Prescale (5'd8),
    
    .Data_Valid (Data_Valid_tb),
    .P_DATA(Rec_Data_tb));
endmodule
