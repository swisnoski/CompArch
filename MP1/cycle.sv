// cycle 
// MP1 project specifications: 
// Your circuit must repeatedly drive the RGB LED on your iceBlinkPico board to cycle through the colors RED, YELLOW, GREEN, 
// CYAN, BLUE, and MAGENTA in that order starting with RED once per second (i.e., the entire cycle repeats once per second).

module top(
    input logic     clk,    // this is the clock
    output logic    RGB_B,  // blue LED 
    output logic    RGB_R,  // red LED
    output logic    RGB_G   // green LED 
    // we can use these as defined in iceBlinkPico.pcf
);

    // CLK frequency is 12MHz, so 6,000,000 cycles is 0.5s
    // so if we want six changes a second, we want 12MHz/6 = 2MHz = 2,000,000 cycles
    parameter BLINK_INTERVAL = 2000000; // so we can set an interval of 2000000. parameter equates to "constant" 

    // clog2(BLINK_INTERVAL) finds log base 2 of 2000000, which allows us to calculate how many bits we 
    // need to count up to 2000000. 2^21 is barely over 2mil, so in this case, clog2(BLINK_INTERVAL) evaluates 
    // to 21, so we need a 21 bit number
    logic [$clog2(BLINK_INTERVAL) - 1:0] count = 0; 
    // so count is the name of our variable. 
    // we use logic instead of parameter because we actually need to change and store this value 

    initial begin // the initial block executes when we load up the program
        RGB_R = 0; // start with only red on. LEDs run active low so assigning a value of 0 means LED is ON 
        RGB_B = 1; // start with blue off (assign high)
        RGB_G = 1; // start with green off (assign high)
    end

    // we need to track our state with three bits (0, 1, 2) to track 6 different states 
    logic [2:0] state = 0; 

    // sooooo system verilog code doesn't execute "in order". we instead define different blocks. 
    // the "always_comb" block is a block that executes based on a signal derived from what's actually 
    // contained within the function, in this case, state. this is different from the always_ff block
    always_comb begin   // but basically we can use this to define a state machine that automatically switches 
                        // case whenever we update the state variable 
                        // note: begin and end just function as braces basically: begin -> {, end -> }

        // there is definetly a better way to do this but for now I'm just going to manually assign each color 
        // as the correct combination of LEDs 
        case(state) 
            0: begin // RED = RED 
                RGB_R = 0;
                RGB_G = 1;
                RGB_B = 1;
            end

            1: begin // YELLOW = RED + GREEN 
                RGB_R = 0;
                RGB_G = 0;
                RGB_B = 1;
            end

            2: begin // GREEN = GREEN 
                RGB_R = 1;
                RGB_G = 0;
                RGB_B = 1;
            end

            3: begin // CYAN = GREEN + BLUE 
                RGB_R = 1;
                RGB_G = 0;
                RGB_B = 0;
            end

            4: begin // BLUE = BLUE 
                RGB_R = 1;
                RGB_G = 1;
                RGB_B = 0;
            end

            5: begin // MAGENTA = RED + BLUE
                RGB_R = 0;
                RGB_G = 1;
                RGB_B = 0;
            end

            // since we have 8 possible cases and only six defined, we need to include a default, 
            // even if it's "impossible" to trigger it in this code 
            default: begin
                RGB_R = 1;
                RGB_G = 1;
                RGB_B = 1;
            end
        endcase
    end
    
    // lastly, we can just slightly modify the original blink code to also change states 
    // always_ff runs everytime the clock updates (12 million times a second) and updates count
    // every sixth of a second, or every "BLINK_INTERVAL", we update to the next state 
    // once we reach state five, we reset to state 0 and begin the cycle again
    always_ff @(posedge clk) begin 
        if (count == BLINK_INTERVAL - 1) begin
            count <= 0;
            if (state == 5) begin
                state <= 0;
            end
            else begin
                state <= state + 1; //update state 
            end
        end

        else begin
            count <= count + 1;     //update count
        end
    end

endmodule