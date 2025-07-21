module ChaCha20 (
    input wire clk,
    input wire rst,

    input wire start,
    output wire busy,
    output wire done,
    input wire mode, // Mode of operation (encryption or decryption)

    input wire [511:0] in_state,
    output wire [511:0] out_state,

    // TRNG interface
    input wire [31:0] trng_data,
    output wire trng_request, 
    input wire trng_ready
);

//Important Internal State Registers

reg [31:0] s [0:15]; // Array of 16 32-bit registers

/*
Pretend it looks like:
[ s0  s1  s2  s3  ]
[ s4  s5  s6  s7  ]
[ s8  s9 s10 s11 ]
[ s12 s13 s14 s15 ]
*/

reg [255:0] current_key;
reg [95:0] current_nonce;
reg [31:0] current_counter;

reg [4:0] round;

endmodule