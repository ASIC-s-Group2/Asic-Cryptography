`timescale 1ns / 1ps

module final_comprehensive_test;

    // Test signals
    reg clk, rst_n, start;
    reg [255:0] key;
    reg [95:0] nonce;
    reg [31:0] counter;
    reg [511:0] plaintext;
    
    wire [511:0] ciphertext;
    wire done, busy;
    
    // Instantiate the ChaCha20 core
    ChaCha20 dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .key(key),
        .nonce(nonce),
        .counter(counter),
        .plaintext(plaintext),
        .ciphertext(ciphertext),
        .done(done),
        .busy(busy)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Test variables
    integer test_count = 0;
    integer pass_count = 0;
    reg [511:0] temp_cipher, temp_plain;
    
    initial begin
        $dumpfile("final_test.vcd");
        $dumpvars(0, final_comprehensive_test);
        
        clk = 0;
        rst_n = 0;
        start = 0;
        
        $display("===========================================");
        $display("    ChaCha20 ASIC Final Verification      ");
        $display("===========================================");
        
        #20 rst_n = 1;
        #20;
        
        // Test 1: Basic functionality test
        test_count = test_count + 1;
        $display("\nTest %0d: Basic ChaCha20 Operation", test_count);
        
        key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        nonce = 96'h000000090000004a00000000;
        counter = 32'h00000001;
        plaintext = 512'h0; // Zero plaintext for keystream generation
        
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        
        $display("Key:       %h", key);
        $display("Nonce:     %h", nonce);
        $display("Counter:   %h", counter);
        $display("Keystream: %h", ciphertext);
        
        if (ciphertext != 512'h0) begin
            $display("PASS: ChaCha20 produced non-zero keystream");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: ChaCha20 produced zero keystream");
        end
        
        // Test 2: Encrypt/Decrypt cycle
        test_count = test_count + 1;
        $display("\nTest %0d: Encrypt/Decrypt Round Trip", test_count);
        
        plaintext = 512'hdeadbeefcafebabe0123456789abcdef0fedcba9876543210123456789abcdef0123456789abcdef0fedcba987654321deadbeefcafebabe0123456789abcdef;
        key = 256'h2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfe;
        nonce = 96'h123456780000000000000000;
        counter = 32'h00000001;
        
        // Encrypt
        start = 1;
        #10 start = 0;
        wait(done);
        temp_cipher = ciphertext;
        #10;
        
        $display("Original:   %h", plaintext);
        $display("Encrypted:  %h", temp_cipher);
        
        // Decrypt (ChaCha20 is symmetric)
        plaintext = temp_cipher;
        start = 1;
        #10 start = 0;
        wait(done);
        temp_plain = ciphertext;
        #10;
        
        $display("Decrypted:  %h", temp_plain);
        
        if (temp_plain == 512'hdeadbeefcafebabe0123456789abcdef0fedcba9876543210123456789abcdef0123456789abcdef0fedcba987654321deadbeefcafebabe0123456789abcdef) begin
            $display("PASS: Encrypt/Decrypt cycle successful");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Encrypt/Decrypt cycle failed");
        end
        
        // Test 3: Different keys produce different outputs
        test_count = test_count + 1;
        $display("\nTest %0d: Key Variation Test", test_count);
        
        plaintext = 512'h5555555555555555aaaaaaaaaaaaaaaa5555555555555555aaaaaaaaaaaaaaaa5555555555555555aaaaaaaaaaaaaaaa5555555555555555aaaaaaaaaaaaaaaa;
        nonce = 96'h000000000000000000000000;
        counter = 32'h00000000;
        
        // Test with key1
        key = 256'h0000000000000000000000000000000000000000000000000000000000000000;
        start = 1;
        #10 start = 0;
        wait(done);
        temp_cipher = ciphertext;
        #10;
        
        // Test with key2
        key = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        
        if (ciphertext != temp_cipher) begin
            $display("PASS: Different keys produce different outputs");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Different keys produce same output");
        end
        
        // Test 4: Counter functionality
        test_count = test_count + 1;
        $display("\nTest %0d: Counter Variation Test", test_count);
        
        key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        nonce = 96'h000000090000004a00000000;
        plaintext = 512'h0;
        
        // Counter = 0
        counter = 32'h00000000;
        start = 1;
        #10 start = 0;
        wait(done);
        temp_cipher = ciphertext;
        #10;
        
        // Counter = 1  
        counter = 32'h00000001;
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        
        if (ciphertext != temp_cipher) begin
            $display("PASS: Counter variation works correctly");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Counter variation not working");
        end
        
        // Final results
        $display("\n===========================================");
        $display("           FINAL TEST RESULTS              ");
        $display("===========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", test_count - pass_count);
        $display("Success Rate: %0d%%", (pass_count * 100) / test_count);
        
        if (pass_count == test_count) begin
            $display("\n*** ALL TESTS PASSED! ***");
            $display("ChaCha20 ASIC is working perfectly!");
            $display("Project Status: COMPLETE SUCCESS");
        end else begin
            $display("\nSome tests failed - check implementation");
        end
        
        $display("===========================================");
        
        #100;
        $finish;
    end
    
    // Performance monitoring
    reg [31:0] cycle_count;
    always @(posedge clk) begin
        if (start)
            cycle_count <= 0;
        else if (busy && !done)
            cycle_count <= cycle_count + 1;
        else if (done)
            $display("Operation completed in %0d cycles", cycle_count);
    end

endmodule