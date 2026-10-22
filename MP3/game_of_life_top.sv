`include "single_cell.sv"
`include "game_of_life.sv"
`include "led_matrix.sv"
`include "ws2812b.sv"
`include "controller.sv"

// game_of_life_top.sv

// this module runs three different games of life (red, green, and blue) and displays
// all three on the same 8x8 LED matrix

module game_of_life_top (
    input  logic clk,        // 12 MHz board clock
    output logic _49a        // the data pin for the matrix board. I chose to use pin 43/_49a as defined in the pcf file
);

    parameter CYCLE_INTERVAL = 6000000;     // we have a 12MHz clock, so a cycle of 6 million ticks will have us loop
                                            // through the cycle every half a second

    logic [$clog2(CYCLE_INTERVAL)-1:0] counter = '0; // as per usual we size our counter based on our interval
    logic next_cycle_signal = 1'b0; // we also declare a next cycle signal 

    // this is where we manage our timer. we have a standard timer where counter runs from 0 to 5999999,
    // and every half a second, it sets next_cycle_signal to 1 for one tick, telling our three game of life
    // modules that we need the next cycle/generation
    always_ff @(posedge clk) begin
        if (counter == CYCLE_INTERVAL - 1) begin
            counter <= '0;
            next_cycle_signal <= 1'b1;
        end
        else begin
            counter <= counter + 1;
            next_cycle_signal <= 1'b0;
        end
    end

    // for each game, we need to keep track of the board state.
    // we do this with a 64 bit array, one bit for each cell, where each cell is
    // either alive (1) or dead (0). the games output to these arrays, and
    // then we pass these arrays to the led_matrix module to be shown on the LEDs
    logic [63:0] red_board;
    logic [63:0] green_board;
    logic [63:0] blue_board;

    // the games themselves also store a copy of the board, so we don't actually need to pass
    // in the board. we just pass in the initial board state as the seed file, and then the module
    // automatically updates the board every time we send it the next_cycle_signal. we also need to 
    // send it the clock, since it uses an always_ff @(posedge clk) to step through its row and column counters

    // so then we just declare our three modules, pass in the seeds, clock, and wire the signals,
    // and we have our three lives simulated!

    // use # to pass a parameter vs set up a wire 
    game_of_life #(.SEED_FILE("seeds/red_seed.memh")) red_GoL (
        .clk          (clk),
        .start_cycle  (next_cycle_signal),
        .return_board (red_board)
    );

    game_of_life #(.SEED_FILE("seeds/green_seed.memh")) green_GoL (
        .clk          (clk),
        .start_cycle  (next_cycle_signal),
        .return_board (green_board)
    );

    game_of_life #(.SEED_FILE("seeds/blue_seed.memh")) blue_GoL (
        .clk          (clk),
        .start_cycle  (next_cycle_signal),
        .return_board (blue_board)
    );

    // so we now have our three board states!

    // lastly, of course, we need to actually display our boards, so we use a simple
    // led_matrix module that wraps and communicates with the ws2812b module

    // the three boards are already wired via the modules, so we just pass the output of the 
    // modules into the display. the boards only update on start_cycle, so all the timing 
    // is handled intrinsically 
    led_matrix display (
        .clk          (clk),
        .red_board    (red_board),
        .green_board  (green_board),
        .blue_board   (blue_board),
        .data_out_pin (_49a)
    );

    // and voila! that's life! 

endmodule
