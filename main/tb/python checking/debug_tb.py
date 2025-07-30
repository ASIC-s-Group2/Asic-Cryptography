"""
Quick testbench issue identifier
"""

def analyze_tb_issues():
    print("🔍 Analyzing potential testbench issues...")
    
    # Read the testbench
    with open('tb/tb_asic_top.sv', 'r') as f:
        tb_content = f.read()
    
    issues_found = []
    
    # Check for common SystemVerilog vs Verilog issues
    if 'initial begin' in tb_content and 'fork' in tb_content:
        print("⚠️  Fork/join with wait() statements can cause deadlocks")
        issues_found.append("fork_join_deadlock")
    
    # Check wait conditions
    wait_lines = [line.strip() for line in tb_content.split('\n') if 'wait(' in line]
    if wait_lines:
        print("🔍 Found wait() statements:")
        for i, line in enumerate(wait_lines[:5]):  # Show first 5
            print(f"  {i+1}: {line}")
        
        # Check for potentially problematic waits
        problematic_waits = []
        for line in wait_lines:
            if 'wait(chunk_request && request_type' in line:
                problematic_waits.append("chunk_request condition")
            if 'wait(tb_in_state_ready)' in line:
                problematic_waits.append("state_ready condition")
            if 'wait(tb_out_state_valid)' in line:
                problematic_waits.append("state_valid condition")
            if 'wait(done)' in line:
                problematic_waits.append("done condition")
        
        if problematic_waits:
            print("❌ Potentially problematic wait conditions:")
            for wait in set(problematic_waits):
                print(f"  - {wait}")
            issues_found.extend(problematic_waits)
    
    # Check module instantiation
    with open('rtl/asic_top.v', 'r') as f:
        asic_content = f.read()
    
    # Look for signal connectivity issues
    tb_signals = []
    asic_ports = []
    
    # Extract signals from testbench instantiation
    in_instantiation = False
    for line in tb_content.split('\n'):
        if 'asic_top U_ASIC_TOP' in line:
            in_instantiation = True
        elif in_instantiation and ');' in line:
            in_instantiation = False
        elif in_instantiation and '.' in line:
            tb_signals.append(line.strip())
    
    print(f"\n📋 Found {len(tb_signals)} signal connections in testbench")
    
    # Check for clock and reset
    clock_found = any('clk' in line.lower() for line in tb_signals)
    reset_found = any('rst' in line.lower() for line in tb_signals)
    
    if not clock_found:
        print("❌ Clock signal not found in instantiation")
        issues_found.append("no_clock")
    else:
        print("✅ Clock signal connected")
    
    if not reset_found:
        print("❌ Reset signal not found in instantiation")
        issues_found.append("no_reset")
    else:
        print("✅ Reset signal connected")
    
    return issues_found

def suggest_fixes(issues):
    print("\n🔧 Suggested fixes:")
    
    if "fork_join_deadlock" in issues:
        print("1. Fork/Join Deadlock Prevention:")
        print("   - Add timeouts to wait() statements")
        print("   - Use #delay statements instead of pure wait()")
        print("   - Check that all waited conditions can actually be satisfied")
    
    if any("condition" in issue for issue in issues):
        print("2. Wait Condition Issues:")
        print("   - Verify that the DUT actually drives the waited signals")
        print("   - Add debug statements before wait() to check signal values")
        print("   - Consider using @(posedge clk) with if() instead of wait()")
    
    if "no_clock" in issues or "no_reset" in issues:
        print("3. Clock/Reset Issues:")
        print("   - Ensure clock generator is working: always #5 clk = ~clk;")
        print("   - Check reset sequence: rst_n = 0; #20; rst_n = 1;")
    
    print("\n4. General debugging tips:")
    print("   - Add $display statements to track simulation progress")
    print("   - Use smaller test cases first")
    print("   - Check VCD file with waveform viewer")
    print("   - Add simulation timeouts with $finish after a max time")

def create_simple_test():
    """Create a very simple test to verify basic functionality"""
    simple_test = '''`timescale 1ns / 1ps

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

endmodule'''
    
    with open('simple_test.sv', 'w') as f:
        f.write(simple_test)
    
    print("✅ Created simple_test.sv for basic functionality testing")

if __name__ == "__main__":
    issues = analyze_tb_issues()
    suggest_fixes(issues)
    create_simple_test()
    
    print("\n🎯 Next steps:")
    print("1. Try running the simple test first: simple_test.sv")
    print("2. If that works, debug the full testbench step by step")
    print("3. Use a simulator like Icarus Verilog, ModelSim, or online tools")
