// smooth_cycle
// MP2 project specifications: 
// In this miniproject, you will use the OSS CAD suite to design a digital circuit to drive the RGB LED on your iceBlinkPico 
// board so that it smoothly cycles through the colors around the HSV color wheel (shown below on the left) once per second 
// by driving the individual LEDs using pulse width modulation (PWM) according to the waveforms shown below on the right.

// Pseudo code 
// we get 12,000,000 clk ticks per second, and we need 360 degrees on the color wheel 
// loosely each LED rise from 0 to 200 over 60 degrees, holds ON for 120 degress, falls from 200->0 over 
// 60 degrees, holds OFF for 120 degrees, and repeats. Each LED just starts at a different point 

`include "pwm.sv"

module top(
    input logic     clk,    // this is the clock
    output logic    RGB_B,  // blue LED 
    output logic    RGB_R,  // red LED
    output logic    RGB_G   // green LED 
    // we can use these as defined in iceBlinkPico.pcf
);
    
    
    // so we need to divide our 12,000,000 ticks into 360 degrees and those 360 degrees into 
    // six increments. that's roughly 33,333 ticks per degrees
    parameter DEGREE_INTERVAL = 33333; // so we can set an interval of 33333

    // and then, just like our blink interval from last time, we need a counter that will count up to our degree 
    // interval and will iterate through our various degrees. we need to be able to count up to 33,333, which is 16 bits,
    // but we can just use $clog2 
    logic [$clog2(DEGREE_INTERVAL) - 1:0] degree_count = 0; 

    // and then we actually need to keep track of what degree we are on, need 9 bits to count up to 360 
    logic [8:0] active_degree = 0; 
    
    // then, we also need to control the pulse width modulation of each LED, which is really just how we control the 
    // brightness of each LED. we will use a counter that tracks between 0 and 100, and we will use that number to 
    // control the PWM signal for each LED. higher number = more "on" cycles
    logic [7:0] red_pwm = 0; // 8 bits gets 256 values, we only want 0-200
    logic [7:0] green_pwm = 0;
    logic [7:0] blue_pwm = 0;

    // and then lastly, we need to configure our PWM clock interval/cycle
    parameter PWM_INTERVAL = 1200;       // CLK frequency is 12MHz, so 1,200 cycles is 100us
    // we could control LEDs with a higher frequency, but kinda unnecessary 
    
    // parameter PWM_SCALE = PWM_INTERVAL / INC_DEC_MAX
    // lastly we can compute PWM_SCALE, which is our PWM_INTERVAL divided by number 
    // of increments we want to use to go from 0 to 199,
    // we can use 200 increments, so PWM_SCALE = 1200 / 200 = 6
    parameter PWM_SCALE = 6;


    // we can use a series of case statements to update the PWM values each time we change the active degree
    // since we are using an always_comb block, when we reassign the value of active_degree, the PWM values will automatically update as well

    // we use active_degree to control two things - which of the six cycles we are in, and how far each LED has risen/fallen in that cycle 
    // so we divide active_degree by 60 to get the cycle, and we use the remainder of that division to figure out how far that cycle has gone 

    // so for example 100 degrees would be cycle 1, increment 40 
    always_comb begin
        case (active_degree / 60) // split active degree 
            0: begin // RED HIGH, GREEN RISE, BLUE LOW
                red_pwm   = 200; 
                green_pwm = ((active_degree % 60) * 200) / 60;
                blue_pwm  = 0;
            end

            1: begin // RED FALL, GREEN HIGH, BLUE LOW
                red_pwm   = ((60 - (active_degree % 60)) * 200) / 60;
                green_pwm = 200;
                blue_pwm  = 0;
            end

            2: begin // RED LOW, GREEN HIGH, BLUE RISE
                red_pwm   = 0;
                green_pwm = 200;
                blue_pwm  = ((active_degree % 60) * 200) / 60;
            end

            3: begin // RED LOW, GREEN FALL, BLUE HIGH
                red_pwm   = 0;
                green_pwm = ((60 - (active_degree % 60)) * 200) / 60;
                blue_pwm  = 200;
            end

            4: begin // RED RISE, GREEN LOW, BLUE HIGH
                red_pwm   = ((active_degree % 60) * 200) / 60;
                green_pwm = 0;
                blue_pwm  = 200;
            end

            5: begin // RED HIGH, GREEN LOW, BLUE FALL
                red_pwm   = 200;
                green_pwm = 0;
                blue_pwm  = ((60 - (active_degree % 60)) * 200) / 60;
            end

            // and then same as last time we need our default case because active degrees/60 could fall outside 
            // the range of 0-5. Doesn't really matter what we set the PWM values to, so we will just set them all to 0
            default: begin
                red_pwm   = 0;
                green_pwm = 0;
                blue_pwm  = 0;
            end
        endcase
    end
    
    // we can use an always_ff loop to control the degree intervals  
    // always_ff runs everytime the clock updates (12 million times a second) and updates count
    // every sixth of a second, or every "DEGREE_INTERVAL", we update to the next state 
    // once we reach degree 359, we reset to state 0 and begin the cycle again
    always_ff @(posedge clk) begin 
        if (degree_count == DEGREE_INTERVAL - 1) begin
            degree_count <= 0;
            if (active_degree == 359) begin
                active_degree <= 0;
            end
            else begin
                active_degree <= active_degree + 1;
            end
        end
        else begin
            degree_count <= degree_count + 1;     //update degree_count
        end
    end 

    // lastly, our PWM module logic is controlled in a seperate module, "pwm.sv"

    // because our logic is seperated, we can just declare the three modules, and feed in clock, the PWM value signal, 
    // and recieve the output signal for each LED

    // declare our three PWM modules, one for each LED, and connect them to the appropriate signals
    // each of our duty values ranges from 0 to 200, but our PWM module needs values between
    // 0 and 1200, so we multiply our values by 6
    pwm pwm_r ( // red LED
        .clk(clk),
        .pwm_value(red_pwm * PWM_SCALE),
        .pwm_out(RGB_R)
    );

    pwm pwm_g ( // green LED
        .clk(clk),
        .pwm_value(green_pwm * PWM_SCALE),
        .pwm_out(RGB_G)
    );

    pwm pwm_b ( // blue LED
        .clk(clk),
        .pwm_value(blue_pwm * PWM_SCALE),
        .pwm_out(RGB_B)
    );

endmodule