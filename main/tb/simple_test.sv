`timescale 1ns / 1ps

module simple_asic_test;

    reg clk, rst_n, start;
    wire busy, done;
    
    // Simple signals for minimal test
    reg [31:0] in_state_word;
    reg in_state_valid;
    wire in_state_ready;
    wire [31:0] out_state_word;
    wire out_state_valid;
    reg out_state_ready;
    
    reg use_streamed_key, use_streamed_nonce, use_streamed_counter;
    reg [1:0] chunk_type;
    reg chunk_valid;
    reg [31:0] chunk;
    wire [4:0] chunk_index;
    wire chunk_request;
    wire [1:0] request_type;
    
    reg [31:0] trng_data;
    reg trng_ready;
    wire trng_request;

    // Instantiate the DUT
    asic_top U_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .in_state_word(in_state_word),
        .in_state_valid(in_state_valid),
        .in_state_ready(in_state_ready),
        .out_state_word(out_state_word),
        .out_state_valid(out_state_valid),
        .out_state_ready(out_state_ready),
        .use_streamed_key(use_streamed_key),
        .use_streamed_nonce(use_streamed_nonce),
        .use_streamed_counter(use_streamed_counter),
        .chunk_type(chunk_type),
        .chunk_valid(chunk_valid),
        .chunk(chunk),
        .chunk_index(chunk_index),
        .chunk_request(chunk_request),
        .request_type(request_type),
        .trng_data(trng_data),
        .trng_ready(trng_ready),
        .trng_request(trng_request)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Simple test sequence
    initial begin
        $dumpfile("simple_test.vcd");
        $dumpvars(0, simple_asic_test);
        
        // Initialize
        clk = 0;
        rst_n = 0;
        start = 0;
        use_streamed_key = 0;
        use_streamed_nonce = 0;
        use_streamed_counter = 0;
        chunk_type = 0;
        chunk_valid = 0;
        chunk = 0;
        in_state_word = 0;
        in_state_valid = 0;
        out_state_ready = 1;
        trng_data = 32'hDEADBEEF;
        trng_ready = 1;
        
        $display("=== Simple ASIC Test Started ===");
        
        // Reset sequence
        #20 rst_n = 1;
        #10;
        
        $display("Reset complete. Starting test...");
        
        // Start the design
        start = 1;
        #10 start = 0;
        
        $display("Start signal sent. Waiting for activity...");
        
        // Wait for some activity or timeout
        repeat(1000) @(posedge clk) begin
            if (busy) $display("Design is busy...");
            if (done) begin
                $display("Design completed!");
                break;
            end
            if (chunk_request) $display("Chunk requested: type=%d, index=%d", request_type, chunk_index);
            if (trng_request) $display("TRNG requested");
        end
        
        $display("=== Test Complete ===");
        $finish;
    end

endmodule