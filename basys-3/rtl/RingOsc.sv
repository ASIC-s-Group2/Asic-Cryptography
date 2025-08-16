<<<<<<< HEAD:basys-3-final/rtl/RingOsc.sv
module RingOsc #(parameter CW = 4) ( //number of oscillators should be odd and equals CW+1
    (*keep*) input RESET,
    output RAW_ENTROPY_OUT
);

	(*keep*) wire [CW:0] chain;
	
	genvar i;
    generate
        for (i=1; i <= CW; i=i+1) 
        begin: not_seq
            assign chain[i] = !chain[i-1];
        end
    endgenerate
	
	assign chain[0] = !(chain[CW]|RESET);

	assign RAW_ENTROPY_OUT = chain[0]; 	
endmodule
=======
module RingOsc #(parameter CW = 4) (
    input wire RESET,
    input wire CLK,
    output wire RAW_ENTROPY_OUT
);

    reg [CW:0] chain;

    always @(posedge CLK or posedge RESET) begin
        if (RESET)
            chain <= 0;
        else
            chain <= chain + 1;
    end

    assign RAW_ENTROPY_OUT = chain[0];

endmodule
>>>>>>> main:main/rtl/RingOsc.v
