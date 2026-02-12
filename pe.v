module pe (
    input clk,
    input rst,
    input [7:0] a_in,  // Input from Left
    input [7:0] b_in,  // Input from Top
    output reg [7:0] a_out, // Pass to Right
    output reg [7:0] b_out, // Pass to Bottom
    output reg [15:0] sum   // Accumulated Result
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_out <= 0;
            b_out <= 0;
            sum   <= 0;
        end else begin
            // 1. Pass data to neighbors
            a_out <= a_in;
            b_out <= b_in;
            
            // 2. MAC Operation (Multiply-Accumulate)
            sum <= sum + (a_in * b_in);
        end
    end
endmodule
