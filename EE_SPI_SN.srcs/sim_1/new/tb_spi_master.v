`timescale 1ns / 1ps

module tb_spi_master;
    // Testbench signals
    reg clk;               // System clock signal
    reg rst_n;             // Active low reset signal
    reg [7:0] data_in;     // Data input for SPI transmission
    reg start;             // Start signal for SPI transmission
    reg interrupt;         // Interrupt signal to trigger data transmission
    wire busy;             // Busy flag indicating ongoing transmission
    wire sck;              // SPI Clock signal
    wire mosi;             // Master Out Slave In signal
    reg miso1;             // Master In Slave Out signal from slave 1
    reg miso2;             // Master In Slave Out signal from slave 2
    wire ss1;              // Slave Select signal for slave 1
    wire ss2;              // Slave Select signal for slave 2
    wire power_on;         // Power on signal for sensors

    // Instantiate the SPI master module
    spi_master uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .start(start),
        .interrupt(interrupt),
        .busy(busy),
        .sck(sck),
        .mosi(mosi),
        .miso1(miso1),
        .miso2(miso2),
        .ss1(ss1),
        .ss2(ss2),
        .power_on(power_on)
    );

    // Clock generation: 100MHz clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Toggle clock every 5ns
    end

    // Test sequence
    initial begin
        // Initialize signals
        rst_n = 0;
        data_in = 8'b10101010;  // Initial data to be transmitted
        start = 0;
        interrupt = 0;
        miso1 = 0;
        miso2 = 0;

        // Release reset after 100ns
        #100 rst_n = 1;

        // First transmission using start signal
        #1000 start = 1;
        #10 start = 0;
        wait(!busy);  // Wait until transmission is complete

        // Wait to observe power management
        #15000; // 15 us

        // Second transmission using interrupt signal
        data_in = 8'b11001100;
        #10 interrupt = 1;
        #10 interrupt = 0; // Short interrupt pulse
        wait(!busy);

        // Wait for power to turn off
        #30000; // 30 us

        // Third transmission to wake up the system using interrupt
        data_in = 8'b00110011;
        #10 interrupt = 1;
        #10 interrupt = 0; // Short interrupt pulse
        wait(!busy);

        // Simulate different sensor inputs
        #5000; // 5 us
        data_in = 8'b01010101; // New sensor data
        #10 start = 1;
        #10 start = 0;
        wait(!busy);

        #10000; // 10 us
        data_in = 8'b11100011; // Another sensor data
        #10 interrupt = 1;
        #10 interrupt = 0;
        wait(!busy);

        // Test with error condition
        #20000; // Wait for power-off
        data_in = 8'b11110000; // Modify data to introduce error
        #10 interrupt = 1;
        #10 interrupt = 0;
        wait(!busy);

        // End simulation
        #1000 $finish;
    end

    // Monitor power_on signal and other important signals
    initial begin
        $monitor("Time %t: power_on = %b, busy = %b, ss1 = %b, ss2 = %b, interrupt = %b, interrupt_pending = %b", 
                 $time, power_on, busy, ss1, ss2, interrupt, uut.interrupt_pending);
    end

    // Display when transmissions start and end
    always @(posedge busy) begin
        $display("Time %t: Transmission started", $time);
    end

    always @(negedge busy) begin
        $display("Time %t: Transmission ended", $time);
    end
endmodule
