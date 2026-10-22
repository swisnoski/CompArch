`timescale 10ns/10ns
`include "game_of_life_top.sv"

// game_of_life_tb.sv

// this is a simple testbench for our design. we just run the top module for a while 
// and save everything to a waveform file

module game_of_life_tb;

    // we just need a clock and the data pin
    logic clk = 0;
    logic _49a;

    // then we set up our top module, all we need to pass in is our clock and data pin.
    // normally it waits half a second between generations, which takes forever to simulate,
    // so we pass in a much shorter CYCLE_INTERVAL to get a new generation every 100000 ticks
    game_of_life_top #(.CYCLE_INTERVAL(100000)) u0 (
        .clk (clk),
        ._49a (_49a)
    );

    // save everything to a waveform file & run for a while
    initial begin
        $dumpfile("game_of_life.vcd");
        $dumpvars(0, game_of_life_tb);
        #10000000
        $finish;
    end

    // and we flip the clock every 4 time steps (40 ns), so one tick is 80 ns, about 12 MHz
    always begin
        #4
        clk = ~clk;
    end

    // to "demonstrate" our simulation results, we can keep track of our board state over 
    // time. every time red_board changes, we print it out in binary, and then we can convert it from
    // a 64 bit signal to an 8x8 board 
    always @(u0.red_board) begin
        $display("%b", u0.red_board);
    end

endmodule


