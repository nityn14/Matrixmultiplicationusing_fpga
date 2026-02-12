module tb_systolic_3x3;

    reg clk, rst, start;
    // Matrix A Inputs
    reg [7:0] a00, a01, a02;
    reg [7:0] a10, a11, a12;
    reg [7:0] a20, a21, a22;
    // Matrix B Inputs
    reg [7:0] b00, b10, b20;
    reg [7:0] b01, b11, b21;
    reg [7:0] b02, b12, b22;
    // Outputs
    wire [15:0] c00, c01, c02;
    wire [15:0] c10, c11, c12;
    wire [15:0] c20, c21, c22;
    wire done;

    systolic_3x3_top uut (
        .clk(clk), .rst(rst), .start(start),
        .a00(a00), .a01(a01), .a02(a02),
        .a10(a10), .a11(a11), .a12(a12),
        .a20(a20), .a21(a21), .a22(a22),
        .b00(b00), .b10(b10), .b20(b20),
        .b01(b01), .b11(b11), .b21(b21),
        .b02(b02), .b12(b12), .b22(b22),
        .c00(c00), .c01(c01), .c02(c02),
        .c10(c10), .c11(c11), .c12(c12),
        .c20(c20), .c21(c21), .c22(c22),
        .done(done)
    );

    always #5 clk = ~clk; // 100MHz clock

    initial begin
        clk = 0; rst = 1; start = 0;
        
        // Define Identity Matrix for A
        // 1 0 0
        // 0 1 0
        // 0 0 1
        a00 = 1; a01 = 0; a02 = 0;
        a10 = 0; a11 = 1; a12 = 0;
        a20 = 0; a21 = 0; a22 = 1;

        // Define Values for B
        // 1 2 3
        // 4 5 6
        // 7 8 9
        b00 = 1; b01 = 2; b02 = 3;
        b10 = 4; b11 = 5; b12 = 6;
        b20 = 7; b21 = 8; b22 = 9;

        #20 rst = 0;
        #10 start = 1; // Load data
        #10 start = 0;

        // Wait for computation
        wait(done);
        #20;
        
        $display("Result Matrix:");
        $display("%d %d %d", c00, c01, c02);
        $display("%d %d %d", c10, c11, c12);
        $display("%d %d %d", c20, c21, c22);
        
        // Expected Result: Should match Matrix B exactly because A is Identity
        $stop;
    end
endmodule
