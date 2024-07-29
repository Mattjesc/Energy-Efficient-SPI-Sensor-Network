`timescale 1ns / 1ps

module spi_slave (
    input wire clk,        // System clock signal
    input wire rst_n,      // Active low reset signal
    input wire sck,        // SPI Clock signal from master
    input wire mosi,       // Master Out Slave In signal from master
    output reg miso,       // Master In Slave Out signal to master
    input wire ss,         // Slave Select signal from master
    output reg [7:0] data_out, // 8-bit data output from slave
    input wire [7:0] data_in,  // 8-bit data input to slave
    output reg data_ready   // Data ready signal to indicate new data received
);

    reg [3:0] bit_cnt;      // Bit counter to track received bits
    reg [7:0] data_reg;     // Register to hold the received data
    reg parity;             // Parity bit for received data
    reg [8:0] tx_data_reg;  // Register to hold the data to be transmitted with parity

    // State Machine states
    localparam IDLE    = 2'b00;
    localparam RECEIVE = 2'b01;
    localparam SEND    = 2'b10;

    // Current state of the state machine
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt <= 4'd0;
            data_reg <= 8'd0;
            miso <= 1'b0;
            data_out <= 8'd0;
            data_ready <= 1'b0;
            parity <= 1'b0;
            tx_data_reg <= 9'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (!ss) begin // When Slave Select is asserted (active low)
                        state <= RECEIVE;
                        bit_cnt <= 4'd0;
                        data_reg <= 8'd0;
                        data_ready <= 1'b0;
                        tx_data_reg <= {data_in, ^data_in}; // Append parity bit to data
                    end
                end
                RECEIVE: begin
                    if (sck == 1'b1) begin // Rising edge of SCK
                        data_reg <= {data_reg[6:0], mosi}; // Shift in the received bit
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 4'd7) begin
                            state <= SEND;
                            data_out <= data_reg; // Store received data
                            data_ready <= 1'b1;  // Set data ready flag
                            parity <= ^{data_reg, mosi}; // Calculate parity for received data
                        end
                    end
                end
                SEND: begin
                    if (sck == 1'b0) begin // Falling edge of SCK
                        if (bit_cnt < 4'd9) begin
                            miso <= tx_data_reg[8 - bit_cnt]; // Shift out the bit including parity
                            bit_cnt <= bit_cnt + 1;
                        end else begin
                            state <= IDLE; // Transmission done, return to IDLE
                            miso <= 1'b0;
                        end
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    // Debug output for state transitions and data reception
    always @(posedge clk) begin
        if (!rst_n) begin
            $display("Time %t: Reset", $time);
        end else begin
            if (state == RECEIVE && sck == 1'b1 && bit_cnt == 4'd7) begin
                $display("Time %t: Data received: %b, Parity: %b", $time, data_reg, parity);
            end
            if (state == SEND && sck == 1'b0) begin
                $display("Time %t: Sending data: %b", $time, tx_data_reg[8 - bit_cnt]);
            end
        end
    end

endmodule
