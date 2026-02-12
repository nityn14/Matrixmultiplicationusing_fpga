module systolic_3x3_top (
    input clk,
    input rst,
    input start, // Pulse this to load inputs and start computing
    
    // Flat inputs for 3x3 Matrix A (Row 0, 1, 2)
    input [7:0] a00, a01, a02,
    input [7:0] a10, a11, a12,
    input [7:0] a20, a21, a22,

    // Flat inputs for 3x3 Matrix B (Col 0, 1, 2)
    input [7:0] b00, b10, b20,
    input [7:0] b01, b11, b21,
    input [7:0] b02, b12, b22,

    // Outputs (The resulting 3x3 Matrix C)
    output [15:0] c00, c01, c02,
    output [15:0] c10, c11, c12,
    output [15:0] c20, c21, c22,
    output done // Goes high when calculation is finished
);

    // Internal wires connecting PEs
    wire [7:0] a_wire [0:2][0:3]; // Horizontal wires
    wire [7:0] b_wire [0:3][0:2]; // Vertical wires
    
    // --- INPUT SKEW LOGIC (The Fix) ---
    // We need shift registers to feed data: 
    // Row 0: Sequence {a02, a01, a00}
    // Row 1: Sequence {a12, a11, a10, 0}
    // Row 2: Sequence {a22, a21, a20, 0, 0}
    
    // Registers to hold the streams
    reg [39:0] row0_sr, row1_sr, row2_sr; // Shift registers for A
    reg [39:0] col0_sr, col1_sr, col2_sr; // Shift registers for B
    reg [3:0] count; // To track when we are done

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            row0_sr <= 0; row1_sr <= 0; row2_sr <= 0;
            col0_sr <= 0; col1_sr <= 0; col2_sr <= 0;
            count <= 0;
        end else if (start) begin
            // Load the buffers with padding (Skewing)
            // Note: Data is loaded LSB first for shifting
            row0_sr <= {8'd0, 8'd0, a02, a01, a00}; 
            row1_sr <= {8'd0, a12, a11, a10, 8'd0}; 
            row2_sr <= {a22, a21, a20, 8'd0, 8'd0}; 

            col0_sr <= {8'd0, 8'd0, b20, b10, b00};
            col1_sr <= {8'd0, b21, b11, b01, 8'd0};
            col2_sr <= {b22, b12, b02, 8'd0, 8'd0};
            count <= 1;
        end else begin
            // Shift data into the array every cycle
            row0_sr <= row0_sr >> 8;
            row1_sr <= row1_sr >> 8;
            row2_sr <= row2_sr >> 8;
            
            col0_sr <= col0_sr >> 8;
            col1_sr <= col1_sr >> 8;
            col2_sr <= col2_sr >> 8;
            
            if (count != 0 && count < 10) count <= count + 1;
        end
    end

    // Signal valid done state (roughly 3*N cycles)
    assign done = (count >= 8);

    // Feed the shifted values into the array edges
    assign a_wire[0][0] = row0_sr[7:0];
    assign a_wire[1][0] = row1_sr[7:0];
    assign a_wire[2][0] = row2_sr[7:0];

    assign b_wire[0][0] = col0_sr[7:0];
    assign b_wire[0][1] = col1_sr[7:0];
    assign b_wire[0][2] = col2_sr[7:0];

    // --- INSTANTIATE 3x3 ARRAY ---
    genvar i, j;
    generate
        for (i = 0; i < 3; i = i + 1) begin : ROWS
            for (j = 0; j < 3; j = j + 1) begin : COLS
                pe PE_INST (
                    .clk(clk),
                    .rst(rst),
                    .a_in(a_wire[i][j]),   // Input from Left
                    .b_in(b_wire[i][j]),   // Input from Top
                    .a_out(a_wire[i][j+1]), // Output to Right
                    .b_out(b_wire[i+1][j]), // Output to Bottom
                    .sum()                  // Internal accumulation
                );
            end
        end
    endgenerate

    // Assign internal PE sums to module outputs
    // Note: We access the 'sum' inside the generated blocks
    assign c00 = ROWS[0].COLS[0].PE_INST.sum;
    assign c01 = ROWS[0].COLS[1].PE_INST.sum;
    assign c02 = ROWS[0].COLS[2].PE_INST.sum;
    
    assign c10 = ROWS[1].COLS[0].PE_INST.sum;
    assign c11 = ROWS[1].COLS[1].PE_INST.sum;
    assign c12 = ROWS[1].COLS[2].PE_INST.sum;
    
    assign c20 = ROWS[2].COLS[0].PE_INST.sum;
    assign c21 = ROWS[2].COLS[1].PE_INST.sum;
    assign c22 = ROWS[2].COLS[2].PE_INST.sum;

endmodule
