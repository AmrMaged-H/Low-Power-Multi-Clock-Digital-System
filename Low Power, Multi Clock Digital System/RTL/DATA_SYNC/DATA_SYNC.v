/*
 Module Name : DATA_SYNC
 
 Functionality:

 The Target Is To Increase The MTBF In case of Having a Bus Going From One Clock
 Domain To Another. However, The Double Flip Flop Synchronizer Has One Cycle
 of Uncertainty And That's Why We Can't Use It to Synchronize A Bus As The
 Data Will Be Corrupted. So, We May Synchronize An Enable Bit Passing Through The
 Domains Instead.
 
 However, This Solution Isn't Valid In Case Of Fast To Slow Crossing
 
 */

`include "CONFIG_MACROS.v"

module DATA_SYNC (input wire CLK,
                  input wire RST,
                  input wire Bus_En,
                  input wire [`WIDTH-1:0] Bus_IN,

                  output reg [`WIDTH-1:0] Sync_Bus,
                  output reg Enable_Pulse);

    /////////////////////////////////////////// Defining The Synchronizer Stages ///////////////////////////////////////////

    reg [`DATA_SYNC_STAGES-1:0] BUS_EN_SyncStages;

    always @(posedge CLK or negedge RST) begin
        if(!RST)
            BUS_EN_SyncStages <= 'd0;
        else
            BUS_EN_SyncStages <= {Bus_En, BUS_EN_SyncStages [`DATA_SYNC_STAGES-1:1] };
    end

    //////////////////////////////////////////// Enable Flip Flop And Pulse Gen. ////////////////////////////////////////////

    reg En_FlipFlop;
    wire Enable_Pulse_Comb;

    always @(posedge CLK or negedge RST) begin
        if(!RST)
            En_FlipFlop <= 'd0;
        else
            En_FlipFlop <= BUS_EN_SyncStages [0];
    end

    assign Enable_Pulse_Comb = (BUS_EN_SyncStages [0]) & (~ En_FlipFlop);

    always @(posedge CLK or negedge RST) begin
        if(!RST)
            Enable_Pulse <= 'd0;
        else
            Enable_Pulse <= Enable_Pulse_Comb;
    end

    /////////////////////////////////////////////////////// Bus Register ////////////////////////////////////////////////////

    wire [`WIDTH-1:0] Sync_Bus_Comb;

    assign Sync_Bus_Comb = (Enable_Pulse_Comb == 1'b1) ? Bus_IN : Sync_Bus;

    always @(posedge CLK or negedge RST) begin
        if (!RST)
            Sync_Bus <= 'd0;
        else
            Sync_Bus <= Sync_Bus_Comb;
    end

    
    
endmodule
