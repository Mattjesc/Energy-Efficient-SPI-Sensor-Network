`timescale 1ns / 1ps

module spi_master (
    input wire clk,         // System clock signal
    input wire rst_n,       // Active low reset signal
    input wire [7:0] data_in, // 8-bit data input to be transmitted via SPI
    input wire start,       // Start signal to initiate SPI transmission
    input wire interrupt,   // Interrupt signal to trigger data transmission
    output reg busy,        // Busy flag to indicate ongoing transmission
    output reg sck,         // SPI Clock signal
    output reg mosi,        // Master Out Slave In signal
    input wire miso1,       // Master In Slave Out signal from slave 1
    input wire miso2,       // Master In Slave Out signal from slave 2
    output reg ss1,         // Slave Select signal for slave 1
    output reg ss2,         // Slave Select signal for slave 2
    output reg power_on     // Power on signal for sensors
);

    reg [3:0] bit_cnt;      // Bit counter to track the number of bits transmitted
    reg [8:0] data_reg;     // Register to hold the data being transmitted, including the parity bit
    reg interrupt_pending;  // Flag to indicate a pending interrupt
    reg parity;             // Parity bit for error detection

    // State Machine states
    localparam IDLE     = 2'b00;
    localparam START    = 2'b01;
    localparam TRANSFER = 2'b10;
    localparam DONE     = 2'b11;

    reg [1:0] state;        // Current state of the state machine

    // Timer for power management
    reg [15:0] idle_counter;
    localparam IDLE_THRESHOLD = 16'd1000; // 10 us at 100MHz clock
    localparam POWER_OFF_DELAY = 16'd200; // 2 us delay before powering off

    reg [1:0] power_state;  // Power management state
    localparam POWER_ON = 2'b00;
    localparam POWER_OFF_WAIT = 2'b01;
    localparam POWER_OFF = 2'b10;

    reg current_slave;      // 0: Slave 1, 1: Slave 2

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt <= 4'd0;
            sck <= 1'b0;
            mosi <= 1'b0;
            ss1 <= 1'b1;
            ss2 <= 1'b1;
            busy <= 1'b0;
            power_on <= 1'b1;
            idle_counter <= 16'd0;
            power_state <= POWER_ON;
            interrupt_pending <= 1'b0;
            parity <= 1'b0;
            current_slave <= 1'b0;
            $display("Time %t: Reset", $time);
        end else begin
            // Handle interrupt
            if (interrupt && state == IDLE) begin
                interrupt_pending <= 1'b1;
                $display("Time %t: Interrupt received and pending", $time);
            end

            // Power management logic
            case (power_state)
                POWER_ON: begin
                    if (state == IDLE && !start && !interrupt_pending) begin
                        if (idle_counter < IDLE_THRESHOLD) begin
                            idle_counter <= idle_counter + 1;
                        end else begin
                            power_state <= POWER_OFF_WAIT;
                            idle_counter <= 16'd0;
                        end
                    end else begin
                        idle_counter <= 16'd0;
                    end
                    power_on <= 1'b1;
                end
                POWER_OFF_WAIT: begin
                    if (idle_counter < POWER_OFF_DELAY) begin
                        idle_counter <= idle_counter + 1;
                        power_on <= 1'b1;
                    end else begin
                        power_state <= POWER_OFF;
                        power_on <= 1'b0;
                    end
                    if (start || interrupt_pending) begin
                        power_state <= POWER_ON;
                        idle_counter <= 16'd0;
                        power_on <= 1'b1;
                    end
                end
                POWER_OFF: begin
                    power_on <= 1'b0;
                    if (start || interrupt_pending) begin
                        power_state <= POWER_ON;
                        idle_counter <= 16'd0;
                        power_on <= 1'b1;
                    end
                end
            endcase

            // SPI state machine logic
            if (power_on) begin
                case (state)
                    IDLE: begin
                        if (start || interrupt_pending) begin
                            state <= START;
                            data_reg <= {data_in, ^data_in}; // Append parity bit to data
                            bit_cnt <= 4'd0;
                            busy <= 1'b1;
                            interrupt_pending <= 1'b0; // Clear the interrupt
                            current_slave <= ~current_slave; // Alternate between slaves
                            $display("Time %t: SPI transmission started (start or interrupt)", $time);
                        end
                    end
                    START: begin
                        if (current_slave == 1'b0) begin
                            ss1 <= 1'b0; // Assert SS1 for Slave 1
                            ss2 <= 1'b1; // Deassert SS2
                        end else begin
                            ss2 <= 1'b0; // Assert SS2 for Slave 2
                            ss1 <= 1'b1; // Deassert SS1
                        end
                        state <= TRANSFER;
                        sck <= 1'b0; // Ensure SCK starts low
                        mosi <= data_reg[8]; // Transmit MSB first (including parity bit)
                    end
                    TRANSFER: begin
                        sck <= ~sck; // Toggle SPI clock
                        if (sck == 1'b0) begin // Falling edge of SCK
                            bit_cnt <= bit_cnt + 1;
                            if (bit_cnt == 4'd8) begin
                                state <= DONE;
                            end else begin
                                mosi <= data_reg[7 - bit_cnt]; // Shift out next bit
                            end
                        end
                    end
                    DONE: begin
                        ss1 <= 1'b1; // Deassert SS1
                        ss2 <= 1'b1; // Deassert SS2
                        busy <= 1'b0;
                        state <= IDLE;
                        sck <= 1'b0; // Ensure SCK ends low
                        mosi <= 1'b0; // Clear MOSI
                        if (parity != ^data_in) begin
                            $display("Time %t: Parity error detected", $time);
                        end else begin
                            $display("Time %t: SPI transmission completed successfully", $time);
                        end
                    end
                    default: state <= IDLE;
                endcase
            end
        end
    end

    // Debug output for power state transitions and signal changes
    always @(posedge clk) begin
        if (power_state == POWER_ON && idle_counter == IDLE_THRESHOLD - 1)
            $display("Time %t: Entering POWER_OFF_WAIT state", $time);
        if (power_state == POWER_OFF_WAIT && idle_counter == POWER_OFF_DELAY - 1)
            $display("Time %t: Entering POWER_OFF state", $time);
        if (start)
            $display("Time %t: Start signal received", $time);
        if (interrupt)
            $display("Time %t: Interrupt signal received", $time);
    end

endmodule
