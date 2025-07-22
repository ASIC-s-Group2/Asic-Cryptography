module RingOsc #(parameter CW = 4) ( //number of oscillators should be odd and equals CW+1
    (* KEEP="TRUE" *) input RESET,
    output RAW_ENTROPY_OUT
);

	(* KEEP="TRUE" *) wire [CW:0] chain;
	
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
