// PWM generator originally from fade LED
// we can repurpose this for each of our LEDs instead

module pwm #(
    parameter PWM_INTERVAL = 1200       // CLK frequency is 12MHz, so 1,200 cycles is 100us
                                        // this is the same as what is used in smmoth_cycle.sv
)(
    input logic clk, // input clock signal
    input logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value,  // input PWM value signal 
    output logic pwm_out // output pwm signal sent to LEDs
);

    // Declare PWM generator counter variable
    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_count = 0;

    // Implement counter for timing transition in PWM output signal
    // this logic is very similar to how we increment our degrees. every time the clock updates, 
    // we increment our counter, and when it reaches the PWM_INTERVAL, we reset it to 0
    always_ff @(posedge clk) begin
        if (pwm_count == PWM_INTERVAL - 1) begin
            pwm_count <= 0;
        end
        else begin
            pwm_count <= pwm_count + 1;
        end
    end

    // the more important part is how we then assign value based on pwm count
    // if the pwm count is greater than or equal to the pwm value, we turn the LED on, otherwise we turn it off
    // so if the pwm value is 0, it will always be lower than/equal to pwm_count, and it will never turn on 
    // if the value is somewhere between 0 and 1200, it will turn on for a portion of the time based on where that value falls, 
    // and if it is 1200, it will always be greater than count and therefore always be on
    assign pwm_out = (pwm_count >= pwm_value) ? 1'b1 : 1'b0;
    // our LEDs are active low, so it sends a value of 1 (OFF) when COUNT is GREATER THAN VALUE, 
    // and a value of 0 (ON) when COUNT is LESS THAN VALUE


endmodule
