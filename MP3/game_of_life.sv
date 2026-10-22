// game_of_life.sv

// this module runs one game of life on an 8x8 board, where the edges wrap around
// (so the left edge touches the right edge, and the top edge touches the bottom edge)

// the board is stored as one flat 64 bit array. the cell at (row, col) is bit row*8 + col. 
// row 0 is the top, col 0 is the left

// every time start_cycle pulses, we walk through all 64 cells one at a time sequentially,
// figure out if each cell is alive or dead in the next generation, write them to a new board, and then
// update the old/return board at once when we're done

module game_of_life #(parameter SEED_FILE = "seeds/default_seed.memh") (
    input logic clk,                    // standard clock
    input logic start_cycle,            // signal wire that triggers the start of a cycle
    output logic [63:0] return_board    // the array we return with an updated board state
);

    // first, we need to load the initial board state
    logic [63:0] current_board;
    logic [7:0] seed [0:7];

    // we can use an initial block to load the seed file when the module starts up
    initial begin
        // we load the seed as an array of 8-bit rows. so seed[0] is the first row
        $readmemh(SEED_FILE, seed);
    end

    // for some reason it doesn't like initializing the seed into the current board in the 
    // initial block, so we just initialize a variable instead and will update the current board 
    // on the first clock edge 
    logic loaded = 1'b0;

    // next, we need a second board, where we will store our new values
    // as we walk over the old board. we can't update the old board while walking over it,
    // since the cells we haven't reached yet still need to see the old neighbors
    logic [63:0] next_board;

    // we also have a single bit cycle_active, which we use to indicate if we are are actively 
    // cycling through the cells. start_cycle is only 1 for a single clock tick, so when start_cycle goes 
    // to 1, we set cycle_active to 1 and keep it there until the cycle ends
    logic cycle_active = 1'b0;

    // lastly, we use two counters to keep track of which row and column we are currently on. 
    // using counters instead of for loops allows us to use only one single_cell module per game of life, 
    // instead of 64 different cells
    logic [2:0] row = 3'd0; // uses three bits to hold values 0-7
    logic [2:0] col = 3'd0;

    // we also need the center cell and the 8 neighbors of the center
    logic center;           // the cell itself
    logic [7:0] neighbors;  // its 8 neighbors

    // we use an always_comb block to wire row/col to center/neighbors, so every
    // time we change our row or col, center and neighbors update as well
    always_comb begin
        // {row, col} is the same as row*8 + col, since row is just the upper 3 bits
        center    = current_board[{row, col}];

        // to get the neighbors we just add or subtract 1 from row and col. we use a
        // three bit 1 (3'd1) so the math wraps around the grid: 7 + 1 = 0 and 0 - 1 = 7
        neighbors = {   current_board[{row-3'd1, col-3'd1}], current_board[{row-3'd1, col}], current_board[{row-3'd1, col+3'd1}],
                        current_board[{row,      col-3'd1}],                                 current_board[{row,      col+3'd1}],
                        current_board[{row+3'd1, col-3'd1}], current_board[{row+3'd1, col}], current_board[{row+3'd1, col+3'd1}] };
    end

    // and then we have our single cell module, and its all important output, next_state.
    // all the cell module does is look at a cell and its neighbors and report
    // if the cell should be alive or dead in the next generation
    logic next_state;
    single_cell game_cell (
        .alive      (center),
        .neighbors  (neighbors),
        .next_state (next_state)
    );

    // now we have everything set up to actually run a game of life cycle.
    // on the very first clock, we load the seed. after that, on start_cycle we set cycle_active
    // to 1. while cycle_active is 1, we step through our row and col counters until we
    // reach the last cell, where we return the new board and set cycle_active back to 0
    always_ff @(posedge clk) begin

        if (!loaded) begin
            // copy the seed onto the board. we list the seed backwards from 7 to 0 because
            // the first item becomes the highest bits, and we want row 0 in bits 0-7
            current_board <= {seed[7], seed[6], seed[5], seed[4],
                              seed[3], seed[2], seed[1], seed[0]};

            // do the sake for the return board 
            return_board  <= {seed[7], seed[6], seed[5], seed[4],
                              seed[3], seed[2], seed[1], seed[0]};

            // and then set loaded permanently to 1, so this will never activate again
            loaded <= 1'b1;
        end

        if (start_cycle) begin
            cycle_active <= 1'b1;
        end

        else if (cycle_active) begin
            // if the cycle is active, we save next_state (which single_cell has already
            // worked out for whatever the current row and col is) into next_board. starts at cell 0,0
            next_board[{row, col}] <= next_state;

            // then we move to the next cell. we go across each row one cell at a time, so
            // if we are in the last column, we go back to column 0 of the next row.
            // otherwise, we just move one to the right
            if (col == 3'd7) begin
                col <= 3'd0;
                row <= row + 3'd1;
            end
            else begin
                col <= col + 3'd1;
            end

            // and if that was the last cell, we end the cycle and return the new board.
            // (row and col both wrap back to 0 on their own, so we're ready for next time)
            if (row == 3'd7 && col == 3'd7) begin
                // notably, next_board doesn't get the last cell until the next clock, so we
                // staple next_state onto the top of next_board ourselves
                current_board <= {next_state, next_board[62:0]};
                return_board  <= {next_state, next_board[62:0]};
                cycle_active  <= 1'b0;
            end
        end
    end

endmodule
