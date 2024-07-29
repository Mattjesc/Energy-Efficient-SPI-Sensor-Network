# Energy-Efficient SPI Sensor Network

![Project Image](https://github.com/user-attachments/assets/spi_project_image.png)

## Overview

This repository contains an implementation of an energy-efficient SPI (Serial Peripheral Interface) sensor network. The project showcases the design of an SPI master that supports multiple slaves, error handling with parity checking, and power management. Event-driven data transmission is achieved using interrupt-driven mechanisms. The project is designed to minimize power consumption and ensure robust communication.

## Project Structure

The project is organized into three main files:

1. **spi_master.v**: The main module implementing the SPI master with power management, error handling, and multiple slave support.
2. **spi_slave.v**: The module implementing the SPI slave to interface with the SPI master.
3. **tb_spi_master.v**: The testbench module for simulating and verifying the functionality of the SPI master and slaves.

### Why?

The project aims to provide a reliable and efficient SPI communication system capable of managing power consumption in sensor networks. This is crucial for applications where energy efficiency is a primary concern, such as in battery-operated or remote sensing devices.

### Key Features

- **Power Management**: The SPI master powers down during idle states and wakes up on activity, significantly reducing power consumption.
- **Error Handling**: Parity checking is implemented to ensure data integrity during transmission.
- **Multiple Slave Support**: The master can communicate with multiple slaves, selecting them using separate slave select signals.
- **Interrupt-Driven Communication**: Event-driven data transmission using interrupt signals allows for efficient and responsive communication.

## Basic Principles and Intuition

### SPI Communication

SPI is a synchronous serial communication protocol used to communicate with peripheral devices. It involves a master device that controls the communication and one or more slave devices. The SPI master generates the clock signal (`sck`), and data is transmitted via the `mosi` (Master Out Slave In) and `miso` (Master In Slave Out) lines.

### Power Management

The power management system is designed to turn off the power during idle states and promptly wake up on activity, thus conserving energy. This is particularly useful in sensor networks where devices may remain idle for extended periods.

### Error Handling

Parity checking is implemented to detect transmission errors. A parity bit is appended to the data, and during reception, the parity is checked to ensure data integrity.

### State Machines and Process Methodologies

State machines are used to manage the different states of SPI communication, power management, and error handling. Two process methodologies are employed:

- **Single Process State Machine (Mealy)**: Both state transitions and output logic are handled within a single always block. This ensures that state and output are updated simultaneously and in sync with the clock, simplifying the design by keeping all the logic within one process.
  - **Application**: Used in the SPI master's power management state machine.

- **Three Process State Machine (Mealy)**: Involves three separate always blocks, one for state transitions, one for output logic, and one for handling specific conditions or actions related to the state transitions. This approach can further modularize the design, making it easier to manage complex state behaviors.
  - **Application**: Used in the SPI master's main state machine and the SPI slave's state machine.

## Detailed Design

### SPI Master Module

The SPI master module handles the communication, power management, and error handling. Here are the key components:

- **State Machine**: Manages the states of the SPI communication (IDLE, START, TRANSFER, DONE).
- **Power Management**: Controls the power state transitions (POWER_ON, POWER_OFF_WAIT, POWER_OFF).
- **Error Handling**: Implements parity checking to detect errors.

#### State Machine

The state machine ensures the correct sequence of operations during SPI communication:
- **IDLE**: Waits for a start or interrupt signal.
- **START**: Prepares for data transmission by asserting the slave select signal.
- **TRANSFER**: Transmits data bits along with the parity bit.
- **DONE**: Ends the transmission and deasserts the slave select signal.

#### Power Management

The power management logic efficiently powers down the system during idle states and wakes it up upon detecting activity:
- **POWER_ON**: The system is powered on and ready for communication.
- **POWER_OFF_WAIT**: Waits for a brief period before powering off.
- **POWER_OFF**: Powers down the system to conserve energy.

#### Error Handling

Parity checking is implemented to ensure data integrity:
- A parity bit is appended to the data. This increases the bit count of each SPI transmission by one, meaning that for an 8-bit data word, 9 bits are transmitted.
- During transmission, the SPI master calculates the parity of the data and appends it as the last bit.
- During reception, the SPI slave also calculates the parity and compares it to the received parity bit to detect any transmission errors.
- If a parity error is detected, a debug message is printed indicating the error.

### SPI Slave Module

The SPI slave module interfaces with the SPI master and handles data reception. Here are the key components:

- **State Machine**: Manages the states of the SPI communication (IDLE, RECEIVE, SEND).

#### State Machine

The state machine ensures the correct sequence of operations during SPI communication:
- **IDLE**: Waits for the slave select signal from the master.
- **RECEIVE**: Receives data bits from the master.
- **SEND**: Transmits data bits back to the master.

### Testbench

The testbench module simulates the SPI master and slave to verify their functionality. It covers various test scenarios, including:
- Different data patterns.
- Simultaneous start and interrupt signals.
- Error conditions and parity checking.
- Power management transitions.

## Simulation Results

### Waveform Screenshots

The simulation waveforms provide insight into the behavior of the SPI master and slave. Below are examples of the waveforms generated during the simulation:

![Waveform 1](waveform_1.png)
![Waveform 2](waveform_2.png)

### Key Observations

- **SS Signals**: The `ss1` and `ss2` signals toggle correctly, indicating proper selection of slaves during transmissions.
- **Power Management**: The `power_on` signal transitions between 1 and 0 based on activity and inactivity.
- **Error Handling**: Parity errors are detected and reported.
- **Interrupt-Driven Communication**: The system promptly responds to interrupt signals.

## Synthesis Results

### Utilization Summary

The synthesis results show the resource utilization for the SPI master design:

- **Slice LUTs**: 49 out of 53,200 (0%)
  - **Explanation**: Slice LUTs (Look-Up Tables) are used for implementing logic functions in the FPGA. The utilization of 49 LUTs indicates that a very small fraction of the available logic resources is used.
- **Slice Registers**: 43 out of 106,400 (0%)
  - **Explanation**: Slice Registers are used for storing state information and sequential logic. Using 43 registers shows that the design has minimal sequential logic requirements.
- **F7 Muxes**: 1 out of 26,600 (0%)
  - **Explanation**: F7 Muxes are used for multiplexer operations within the FPGA. The utilization of 1 F7 Mux indicates minimal use of complex mux operations.
- **Bonded IOBs**: 18 out of 200 (9%)
  - **Explanation**: Bonded IOBs (Input/Output Blocks) are used for interfacing the FPGA with external signals. The utilization of 18 IOBs is related to the number of input/output signals in the design.
- **BUFGCTRLs**: 1 out of 32 (3%)
  - **Explanation**: BUFGCTRLs (Global Clock Buffers) are used for distributing clock signals within the FPGA. Using 1 BUFGCTRL indicates the design has a single clock domain.

### Timing Summary

The timing summary indicates that the design meets the required timing constraints:

- **Worst Negative Slack (WNS)**: inf
  - **Explanation**: WNS (Worst Negative Slack) indicates the worst-case timing violation in the design. An infinite value means there are no violations.
- **Total Negative Slack (TNS)**: 0.000 ns
  - **Explanation**: TNS (Total Negative Slack) is the sum of all negative slacks in the design. A value of 0.000 ns indicates no timing violations.
- **Worst Hold Slack (WHS)**: inf
  - **Explanation**: WHS (Worst Hold Slack) indicates the worst-case hold time violation. An infinite value means there are no violations.
- **Total Hold Slack (THS)**: 0.000 ns
  - **Explanation**: THS (Total Hold Slack) is the sum of all hold time violations. A value of 0.000 ns indicates no hold time violations.
- **Number of Failing Endpoints**: 0
  - **Explanation**: The number of endpoints that fail to meet timing constraints. A value of 0 indicates that all timing constraints are met.

### Power Estimation

The power estimation provides insights into the power consumption of the design:

- **Total On-Chip Power**: 1.459 W
  - **Explanation**: The total power consumed by the FPGA chip.
- **Dynamic Power**: 1.330 W (91%)
  - **Explanation**: Power consumed due to switching activity of logic and signals.
  - **Signals**: 0.185 W (14%)
    - **Explanation**: Power consumed by signal transitions.
 

 - **Logic**: 0.108 W (8%)
    - **Explanation**: Power consumed by logic operations.
  - **I/O**: 1.036 W (78%)
    - **Explanation**: Power consumed by input/output operations.
- **Device Static Power**: 0.129 W (9%)
  - **Explanation**: Static power consumption due to leakage currents and other static effects.
- **Junction Temperature**: 41.8°C
  - **Explanation**: Estimated temperature of the FPGA junction based on power consumption and thermal properties.

### Design Rule Check (DRC) Summary

The DRC summary shows that there are critical warnings related to pin planning and PS7 block requirements. These warnings indicate that:

- **All logical ports need a user-specified I/O standard value.**
  - **Explanation**: To ensure compatibility with the board and correct operation, I/O standards need to be explicitly defined.
- **All logical ports need a user-specified location constraint (LOC).**
  - **Explanation**: Specific pin locations should be assigned to avoid I/O contention and ensure proper connectivity.
- **The PS7 cell must be used in this Zynq design to enable correct configuration.**
  - **Explanation**: The PS7 block is required for the proper functioning of the Zynq design.
- **Note**: These warnings appear because the project board selected during creation is the ZedBoard Zynq Evaluation and Development Kit (xc7z020clg484-1) - Zynq-7000 Product Family. Since the design has not been mapped to specific hardware, these warnings are expected. They indicate that certain implementation-specific details would need to be addressed when moving to hardware.

## Conclusion

This project demonstrates an energy-efficient SPI sensor network with robust error handling, power management, and multiple slave support. The simulation results validate the design's functionality and efficiency. Although the project has not been tested on real hardware due to financial constraints, the synthesis and DRC results indicate that the design is well-optimized and ready for implementation.

For more detailed information on the signals and simulation results, please refer to the comments within the source code files.

### Disclaimer

This project has not been tested on a real FPGA board yet due to financial constraints. The synthesis and DRC results have been analyzed to ensure the design is sound and ready for hardware testing when resources become available.