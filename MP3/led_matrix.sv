// led_matrix.sv

// this is where we take in our three game boards and output them to the LED matrix
// we reuse the controller and we2812b modules from the led_matrix example

module led_matrix (
    input  logic clk,  // 12 MHz board clock
    input  logic [63:0] red_board,      // we of course need our three boards 
    input  logic [63:0] green_board,
    input  logic [63:0] blue_board,
    output logic data_out_pin // and we need to pass in the data pin as well
);

    // the basic logic is we have is:
    // use an led control to manage time 
    // assign value based on the three matricies 
    // pass value onto LED 

    // pixel tracks which cell of the array we are in, 0-63
    logic [5:0] pixel;           

    // holds the 24 bit color of the current LED, 8 values each for red, blue, and green
    logic [23:0] shift_reg = 24'd0;   

    // load_sreg helps us keep time, it output by the controller, and goes high
    // when it's time to load the next LED's color
    logic load_sreg;               

    //similarly, logic shift pulses every time we use the ws2812b to grab a bit
    logic shift;                   


    // we also just have this leftover frame value, which we don't use but need to keep 
    // in order to properly use the controller. 
    logic [4:0] frame;             

    // Instance the controller
    // the controller just takes in the clock and outputs everything else 
    // the important things here are pixel, which tells us which pixel we are on 
    controller led_controller (
        .clk            (clk),
        .load_sreg      (load_sreg),
        .transmit_pixel (transmit_pixel_signal),
        .pixel          (pixel),
        .frame          (frame)
    );

    // Instance the WS2812B output driver
    // this sends the our board to the matrix one bit at a time through our data out pin,
    // based on the color defined in our shift_register, when the transmit pixel signal is high,
    // and then it shifts to the next bit
    ws2812b led_driver (
        .clk            (clk),
        .serial_in      (shift_reg[23]),
        .transmit       (transmit_pixel_signal),
        .ws2812b_out    (data_out_pin),
        .shift          (shift)
    );

    always_ff @(posedge clk) begin
        // load the current LED's color, in green, red, blue order.
        // each color is on if that game's cell is alive
        if (load_sreg) begin
            shift_reg <= { {8{green_board[pixel]}}, {8{red_board[pixel]}}, {8{blue_board[pixel]}} };
        end

        // every time ws2812b grabs a bit, shift left so the next bit is on top
        else if (shift) begin
            shift_reg <= { shift_reg[22:0], 1'b0 };
        end
    end

endmodule
