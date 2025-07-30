`timescale 1ns / 1ps

// Basic functionality test without SystemVerilog features
module basic_asic_test;

    reg clk, rst_n, start;
    wire busy, done;
    
    // Test signals
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
    
    wire [31:0] trng_data;
    wire trng_ready;
    wire trng_request;

    // Instantiate the mock TRNG
    MockTRNGHardened mock_trng (
        .clk(clk),
        .rst_n(rst_n),
        .trng_request(trng_request),
        .random_number(trng_data),
        .ready(trng_ready)
    );

    // Instantiate the DUT
    asic_top dut (
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

    // Test sequence
    initial begin
        $dumpfile("basic_test.vcd");
        $dumpvars(0, basic_asic_test);
        
        // Initialize signals
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
        
        $display("=== Basic ASIC Test Started ===");
        
        // Reset sequence
        #20 rst_n = 1;
        #10;
        
        $display("Reset complete. Design state - Busy: %b, Done: %b", busy, done);
        
        // Test 1: Just check if design responds to start
        $display("Test 1: Checking start response...");
        start = 1;
        #10 start = 0;
        
        // Wait a bit and check status
        #50;
        $display("After start - Busy: %b, Done: %b, Chunk_req: %b, TRNG_req: %b", 
                 busy, done, chunk_request, trng_request);
        
        // If TRNG is requested, we know the design is using TRNG mode
        if (trng_request) begin
            $display("Design is requesting TRNG data - providing mock data");
            // The MockTRNG should handle this automatically
        end
        
        // If chunk is requested, we know the design wants streamed input
        if (chunk_request) begin
            $display("Design is requesting chunk data - Type: %b, Index: %d", 
                     request_type, chunk_index);
        end
        
        // Wait longer to see what happens
        #1000;
        
        $display("Final state - Busy: %b, Done: %b", busy, done);
        
        if (done) begin
            $display("✅ Design completed successfully!");
        end else if (busy) begin
            $display("⚠️  Design is still busy - may need more input or time");
        end else begin
            $display("❓ Design is idle - check if it started properly");
        end
        
        $display("=== Test Complete ===");
        $finish;
    end

    // Safety timeout
    initial begin
        #10000;
        $display("TIMEOUT: Test exceeded maximum time");
        $finish;
    end

endmodule
