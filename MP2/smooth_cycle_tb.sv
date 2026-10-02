// for our testbench, we can simply declare our smooth module 
// with RGB inputs, and then start the three pwm modules with 
// each of the LEDs. 

`timescale 1ns/1ps 
`include "smooth_cycle.sv"

// im a perfectionist so i changed the timescale and always begin counter
// to be more accurate and create a test bench cycle that is exactly 1 second long

module smooth_cycle_tb;

    logic clk = 0;
    logic RGB_B;
    logic RGB_R;
    logic RGB_G;

    smooth_cycle u0 (
        .clk   (clk),
        .RGB_B (RGB_B),
        .RGB_R (RGB_R),
        .RGB_G (RGB_G)
    );

    initial begin
        $dumpfile("smooth_cycle.vcd");
        $dumpvars(0, smooth_cycle_tb);
        #100000000
        $finish;
    end

    always begin
        #4.16667
        clk = ~clk;
    end

endmodule