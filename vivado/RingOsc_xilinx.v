module RingOsc #(parameter CW = 4) ( //number of oscillators should be odd and equals CW+1
    (* KEEP = "true", DONT_TOUCH = "true" *) input RESET,
    output RAW_ENTROPY_OUT
);

	(* KEEP = "true", DONT_TOUCH = "true" *) wire [CW:0] chain;
	
	genvar i;
    generate
        for (i=1; i <= CW; i=i+1) begin: not_seq
            (* KEEP = "true", DONT_TOUCH = "true" *)
            LUT1 #(.INIT(2'b01)) inverter (
                .I0(chain[i-1]),
                .O(chain[i])
            );
        end
    endgenerate
	
	(* KEEP = "true", DONT_TOUCH = "true" *)
    LUT2 #(.INIT(4'b0001)) feedback (
        .I0(chain[CW]),
        .I1(RESET),
        .O(chain[0])
    );

	assign RAW_ENTROPY_OUT = chain[0]; 	
endmodule
