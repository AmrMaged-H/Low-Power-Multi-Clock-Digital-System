/*

Module Name: FSM

Functionality:
    The FSM Switches Between:
    1- IDLE
    2- START
    3- DATA
    4- PARITY
    5- STOP

    and it controls other signals related to the other modules

 */

`include "CONFIG_MACROS.v"

module RX_FSM  (input wire CLK,
                input wire RST,
                input wire RX_IN,
                input wire PAR_EN,
                input wire par_err,
                input wire strt_glitch,
                input wire stp_err,
                input wire [`BIT_COUNTER_WIDTH-1:0] bit_cnt,
                input wire [4:0] edge_cnt,
                input wire [4:0] Prescale,

                output wire par_chk_en,
                output wire strt_chk_en,
                output wire stp_chk_en,
                output reg Data_Valid,
                output wire deser_en,
                output reg edge_count_en,
                output reg data_sample_en,
                output reg StartTransition);
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////// State Encoding ////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    localparam IDLE   = 3'd0;
    localparam START  = 3'd1;
    localparam DATA   = 3'd2;
    localparam PARITY = 3'd3;
    localparam STOP   = 3'd4;
    
    reg [2:0] PS, NS;
    
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            PS <= IDLE;
        else
            PS <= NS;
    end

    /////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////// Edge Count Enable //////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    // --> The edge_count_en should be asserted When Switching From IDLE to START In
    // Order To Count The Edges of the Start Bit Properly and It Should be
    // de-asserted When Switching From Stop To Idle Or When We Remain IDLE Or
    // In the case of strt_glitch (Switching From START To IDLE)

    always @(posedge CLK or negedge RST) begin
        if (!RST)
            edge_count_en <= 0;
        else if (PS == IDLE && NS == START)
            edge_count_en <= 1;
        else if ((PS == STOP || PS == START) && NS == IDLE)
            edge_count_en <= 0;
    end

    /////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////// Next State Logic ///////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    always @(*) begin

        case (PS)
            IDLE : begin
                if (!RX_IN) 
                    NS = START;                  
                else 
                    NS = IDLE;
            end
            
            START : begin
                if (strt_glitch) 
                    NS = IDLE;
                else if (edge_cnt == (Prescale - 2))
                    NS = DATA;
                else 
                    NS = START;
            end
            
            DATA : begin
                if (PAR_EN && edge_cnt == (Prescale - 1) && bit_cnt == `WIDTH)
                    NS = PARITY;
                else if (edge_cnt == (Prescale - 1) && bit_cnt == `WIDTH)
                    NS = STOP;
                else
                    NS = DATA;
            end
            
            PARITY : begin
                if (edge_cnt == (Prescale - 1))
                    NS = STOP;
                else
                    NS = PARITY;
            end
            
            STOP : begin           
                if (edge_cnt == (Prescale - 1)) 
                    NS = IDLE;
                else
                    NS = STOP;
            end
            default: NS = IDLE;
        endcase
    end
        
    /////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// Check Enable Flags //////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////
        
    // For Prescale = 8, The par_chk_en Flag Should be Asserted When we are in the 
    // 6th Cycle (edge_cnt = 5) Of the PARITY State. So, The Sample Will Be Ready 

    wire [4:0] LastSample_Cycle;

    assign LastSample_Cycle = Prescale >> 1;
        
    assign par_chk_en = ((PS == PARITY) && (edge_cnt == LastSample_Cycle+2)) ? 1'b1 : 1'b0;
        
        // And The Same Procedure Can Be Applied For the Other Flags ...
        
    assign strt_chk_en = ((PS == START) && (edge_cnt == LastSample_Cycle+2)) ? 1'b1 : 1'b0;
    assign stp_chk_en  = ((PS == STOP) && (edge_cnt == LastSample_Cycle+2))  ? 1'b1 : 1'b0;
        
        
    /////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////// data_sample_en /////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////

    // If the Prescale is 4,  We should enable the Sampler at the Edge Counts: 0,1,2
    // If the Prescale is 8,  We should enable the Sampler at the Edge Counts: 2,3,4
    // If the Prescale is 16, We should enable the Sampler at the Edge Counts: 6,7,8
    // If the Prescale is 32, We should enable the Sampler at the Edge Counts: 14,15,16

    always @(*) begin
        if (edge_cnt == LastSample_Cycle || edge_cnt == LastSample_Cycle-1 || edge_cnt == LastSample_Cycle-2)
            data_sample_en = 1'b1;
        else 
            data_sample_en = 1'b0;
    end

    /////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////// Data_Valid and deser_en //////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////
        
    always @(posedge CLK or negedge RST) begin
        if(!RST) begin
            Data_Valid <= 1'b0;
        end
        else if (PS == STOP && NS == IDLE) begin
            if (!stp_err && !par_err) 
                Data_Valid <= 1'b1;
            else 
                Data_Valid <= 1'b0;
        end
        else if (PS == IDLE && NS == START) 
            Data_Valid <= 1'b0;
    end

    assign deser_en = (PS == DATA && (edge_cnt == LastSample_Cycle+1))? 1'b1:1'b0;

    /////////////////////////////////////////////////////////////////////////////////////////////

    always @(posedge CLK or negedge RST) begin
        if (!RST)
            StartTransition <= 0;
        else if (PS == IDLE && NS == START)
            StartTransition <= 1;
        else if (PS == START && NS == DATA)
            StartTransition <= 0;
    end
        
endmodule
