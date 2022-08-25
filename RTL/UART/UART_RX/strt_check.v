module strt_check (input wire strt_chk_en,
                   input wire sampled_bit,
                   output reg strt_glitch);

    always @(*) begin
        if (strt_chk_en && sampled_bit) 
            strt_glitch = 1'b1;
        else
            strt_glitch = 1'b0;
    end
            
endmodule
