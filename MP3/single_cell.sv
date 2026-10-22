// single_cell.sv

// all single cell does is we give it a cell and its 8 neighbors, and it
// tells us whether that cell will be alive in the next generation

// each game_of_life module has only one of these, and reuses it for all
// 64 cells, one cell per clock cycle. we do this to save on logic gates

module single_cell (
    input  logic alive,       // 1 if this cell is alive right now, 0 if dead 
    input  logic [7:0] neighbors,   // its 8 neighbors, 1 if alive, 0 if dead 
    output logic next_state   // 1 if this cell will be alive next generation, 0 if dead 
);

    // the logic here is very simple. all we do is count up all the neighbors, which 
    // gives us a value between 0 and 8
    logic [3:0] count;
    assign count = neighbors[0] + neighbors[1] + neighbors[2] + neighbors[3]
                 + neighbors[4] + neighbors[5] + neighbors[6] + neighbors[7];



    // and then we check the two conditions were the cell might be alive 
    // and set it as an or condition. Either we have exactly three neighbors or 
    // the cell is alive and we have exactly two neighbors. 
    assign next_state = (count == 4'd3) || (alive && (count == 4'd2));

endmodule
