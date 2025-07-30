// Mock TRNGHardened module for simulation purposes
module MockTRNGHardened (
    input wire clk,
    input wire rst_n, // Active-low reset
    input wire trng_request, // Request from ASIC
    output reg [31:0] random_number,
    output reg ready // TRNG asserts when random_number is valid
);

    reg [31:0] internal_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            internal_counter <= 0;
            random_number <= 0;
            ready <= 0;
        end else begin
            ready <= 0; // Default to not ready
            if (trng_request) begin
                // In a real TRNG, this would take time to generate entropy.
                // For mock, we make it ready in the next cycle.
                internal_counter <= internal_counter + 1; // Generate next 'random' number
                random_number <= internal_counter + 1; // Output the next number
                ready <= 1; // Signal readiness
            end
        end
    end
endmodule