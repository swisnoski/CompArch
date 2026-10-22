okay just need a place to jot down my thoughts   

from what I've seen online, it seems that creating a single cell module and looping 
over a binary array of "cells" is the most effective way to compactly track each of 64 states at once.   

so essentially, we have an input arry of 64 cells. This array needs to remain untouched until we process each and every cell of this array, ie, we can't touch any of the cells on the input array. Instead, we will declare an output array and iterate through THOSE cells 

so we can have a simple cell module that takes in a 3x3 grid. so we can just have the eight neighbors and we need to know if the center cell is alive also. so essentially we can convert an nine digit binary string (from the previous 8x8 array) into a single binary that then gets passed into the new array   

so we want to loop through two indexes, row and cell, and take the neighbors as we move. we will want to consider edge cases for the edge of the grid, where we wrap around the edge of the board. 

this way, we use a pretty limited number of logic gates, as we can keep reusing the same module over and over again. 

so right now we have 
one module for game of life 
one module for cells 

and THEN, on top of that, we need a module that somehow communicates to the LED board. so that basically takes our output of the 8x8 binary array and converts it to something the LED board can read. this also allows us to mess with multiple different games happening simultaneously as required by part two of the project. 

so now we have 

1. cell module that takes in an nine digit binary and outputs a single binary 
2. game of life that loops over a board state, declaring a new state every second, looping over an 8x8 binary array (or vector of vectors, need to look into this)
    b. game of life also needs to be initialized with a starting position 
3. a top module that initializes one or more games of life, reads their board state(s) once a second, and translates the 8x8 binary array(s) onto the LED 


okay. so HOW do we do this? 

so the first step is to initialize a one second time, which we've done before. every one second, we "begin" a cycle of creating a new state via looping through the old state, calculating the new state by reusing the same logic module over and over (determining input using muxes).

so once we begin a cycle (always_ff(posedge)), we loop one by one through the grid. We use two iterators to keep track of the center cell row and column, and calculate the neighbors based on those iterators. We then pass all 9 digits to the cell module and get a binary value, blah blah blah. we will iterate these counters in the cycle.

on a cycle trigger, we do all of this sequentially for each active game (although each game will have it's own single cell). Then, once ALL games have returned their boards, (or output them or whatever), we can send the final display to the LED board.


and maybe we want to have one more module to control the LED specifically so our top module can be really really really simple 

so our modules become, in more detail this time: 
1. single_cell
- inputs: alive/dead, neighboring cells alive/dead (9 bits)
- outputs: alive/dead (1 bit)

2. game_of_life
- inputs: clock 
- inputs: start_cycle (binary)
- inputs: starting_state file 
- imports single cell module (uses one cell module per game)
- stores current_board and next_board 
- on start_cycle, loops through cells until done (loops by row and column)
- after last cell (cell 7,7) switches start cycle and returns next board to top module, and sets current board as next board

3. game_of_life_top
- controls 1 second timer 
- creates games of life 
- when game returns board states, updates led matrix 

4. led_matrix 
- input: 8x8 matrix of color 
-output: 8x8x24 bit arry to matrix module to do color control

5. ws2812b.sv
- upon recieving data, updates the matrix to reflect recieved data 
- handles all communication with matrix 



okay! cool - now some more complex stuff. how do we actually index through the 64 bit array successfully, and how do we find the neighbors? presumably we can use just binary addition/subraction but let's think this through. 

so for iteration, we can use two 3 bit iterators storing values 0-7 based on the row and the column. 

if we declare these as specifically 3 bit binary numbers, than adding and subtracting to find the proper row and column will automatically roll the binary number over. 111 + 1 = 000, and 000 - 1 = 111.

so we can simply add and subract from the row and column indexes to find all of the neighbors, which we will add to a single array and send to the cell module.

we also cannot use for loop for the cell iteration, since using for loops is the equivilent of creating a single cell module for each cell (64 modules). instead, we use the clock to iterate through the indexes and update them one at a time until we reach the end. 

when we send the 9 digit binary to the cell module, we can declare the first digit as signifying if the center cell (the cell currently being iterated over) is alive or dead. We then need to figure our if the cell has: 
1. less than 2 neighbors -> dies no matter what 
2. exactly 2 neighbors -> alive if cell is alive, otherwise dead 
3. exactly three neighbors -> alive no matter what 
4. more than three neighbors -> dies no matter what 

