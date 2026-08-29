# Dual_Clk_FIFO
# Asynchronous FIFO using SystemVerilog

## Overview

This project implements an **Asynchronous FIFO (First-In First-Out) using SystemVerilog**.

An Asynchronous FIFO is used for transferring data between two different clock domains. Unlike a synchronous FIFO, the write and read operations are controlled by **independent clocks**.

The FIFO implemented in this project has a **16-location memory with 8-bit data width**. The design uses binary read/write pointers, Gray-code conversion, clock-domain synchronizers, and full/empty flag generation.

The design and testbench were developed and **verified using EDA Playground**.

## Features

* Asynchronous FIFO design
* Dual-clock operation
* 8-bit data width
* 16 memory locations
* Independent write and read clock domains
* Binary read/write pointers
* Binary-to-Gray code conversion
* Two-stage pointer synchronization
* Full flag generation
* Empty flag generation
* FIFO memory read/write operations
* SystemVerilog testbench for functional verification
* Simulation and waveform verification using EDA Playground

## FIFO Specifications

| **Parameter**       | **Value**               |
| ------------------- | ----------------------- |
| FIFO Type           | Asynchronous FIFO       |
| Data Width          | 8 bits                  |
| FIFO Depth          | 16 locations            |
| Memory Size         | 16 × 8 bits             |
| Write Clock         | `wr_clk`                |
| Read Clock          | `rd_clk`                |
| Write Enable        | `wr_en`                 |
| Read Enable         | `rd_en`                 |
| Write Reset         | `wr_rst`                |
| Read Reset          | `rd_rst`                |
| Full Flag           | `full`                  |
| Empty Flag          | `empty`                 |
| Design Language     | SystemVerilog           |
| Verification        | SystemVerilog Testbench |
| Simulation Platform | EDA Playground          |

## Inputs

| **Input** | **Width** | **Description**                |
| --------- | --------: | ------------------------------ |
| `wr_clk`  |     1 bit | Write clock                    |
| `wr_rst`  |     1 bit | Active-high write-domain reset |
| `wr_en`   |     1 bit | Enables FIFO write operation   |
| `wr_data` |    8 bits | Data written into FIFO         |
| `rd_clk`  |     1 bit | Read clock                     |
| `rd_rst`  |     1 bit | Active-high read-domain reset  |
| `rd_en`   |     1 bit | Enables FIFO read operation    |

## Outputs

| **Output** | **Width** | **Description**                                   |
| ---------- | --------: | ------------------------------------------------- |
| `full`     |     1 bit | Indicates that FIFO cannot accept more data       |
| `rd_data`  |    8 bits | Data read from FIFO                               |
| `empty`    |     1 bit | Indicates that FIFO has no data available to read |

## FIFO Memory

The FIFO memory is implemented as:

```systemverilog
logic [7:0] mem [0:15];
```

This represents:

* **16 memory locations**
* **8-bit data at each location**

Therefore, the total storage capacity is:

**16 × 8 = 128 bits**

The lower four bits of the read and write pointers are used to address the 16 memory locations.

## Pointer Architecture

The FIFO uses separate pointers for the write and read operations:

```systemverilog
logic [4:0] wr_ptr_bin;
logic [4:0] rd_ptr_bin;
```

The pointers are **5 bits wide** even though the FIFO contains 16 locations.

The extra MSB is used to distinguish between the **full** and **empty** conditions when the address portions of the pointers are equal.

The pointer structure can be represented as:

```text
5-bit Pointer

┌─────┬────────────┐
│ MSB │ 4-bit Addr │
└─────┴────────────┘
   │        │
   │        └── Selects 16 memory locations
   │
   └── Used for Full/Empty detection
```

## Binary to Gray Code Conversion

The binary read and write pointers are converted into Gray code.

The conversion is performed using:

```systemverilog
gray = binary ^ (binary >> 1);
```

For example:

```systemverilog
wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);
```

and:

```systemverilog
rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);
```

Gray code is used for clock-domain crossing because only **one bit changes between consecutive Gray-code values**, reducing the possibility of multiple-bit transitions being sampled incorrectly.

## Clock Domain Crossing

The FIFO contains two independent clock domains:

```text
Write Domain                     Read Domain
-------------                    ------------

   wr_clk                           rd_clk
      │                                │
      ▼                                ▼
Write Pointer                     Read Pointer
      │                                │
      ▼                                ▼
 Gray Code                         Gray Code
      │                                │
      └──────────────┐  ┌─────────────┘
                     │  │
                     ▼  ▼
               Synchronizers
                     │  │
                     ▼  ▼
              Other Clock Domain
```

The write pointer needs to be transferred to the read clock domain, while the read pointer needs to be transferred to the write clock domain.

Two flip-flops are used for synchronization.

### Write Pointer Synchronization

The write pointer is synchronized into the read clock domain:

```systemverilog
always_ff @(posedge rd_clk or posedge rd_rst) begin
    if (rd_rst) begin
        wr_sync_ff1      <= 5'b00000;
        wr_ptr_gray_sync <= 5'b00000;
    end
    else begin
        wr_sync_ff1      <= wr_ptr_gray;
        wr_ptr_gray_sync <= wr_sync_ff1;
    end
end
```

### Read Pointer Synchronization

The read pointer is synchronized into the write clock domain:

```systemverilog
always_ff @(posedge wr_clk or posedge wr_rst) begin
    if (wr_rst) begin
        rd_sync_ff1      <= 5'b00000;
        rd_ptr_gray_sync <= 5'b00000;
    end
    else begin
        rd_sync_ff1      <= rd_ptr_gray;
        rd_ptr_gray_sync <= rd_sync_ff1;
    end
end
```

The two-stage synchronizers help reduce the risk of **metastability during clock-domain crossing**.

## How the FIFO Works

The FIFO performs two independent operations:

```text
WRITE SIDE                         READ SIDE

wr_en                              rd_en
  │                                  │
  ▼                                  ▼
Check FULL                       Check EMPTY
  │                                  │
  ▼                                  ▼
Not FULL                         Not EMPTY
  │                                  │
  ▼                                  ▼
Write Data                       Read Data
  │                                  │
  ▼                                  ▼
Increment                        Increment
Write Pointer                    Read Pointer
  │                                  │
  ▼                                  ▼
Binary → Gray                    Binary → Gray
```

The pointers are continuously synchronized between the two clock domains so that each side can determine whether the FIFO is full or empty.

## Write Operation

Data is written into the FIFO on the rising edge of `wr_clk`.

```systemverilog
always_ff @(posedge wr_clk) begin
    if (wr_en && !full)
        mem[wr_ptr_bin[3:0]] <= wr_data;
end
```

A write occurs only when:

```text
wr_en = 1
full  = 0
```

The lower four bits of `wr_ptr_bin` select one of the 16 FIFO memory locations.

After a successful write, the write pointer is incremented.

## Read Operation

Data is read from the FIFO on the rising edge of `rd_clk`.

```systemverilog
always_ff @(posedge rd_clk) begin
    if (rd_en && !empty)
        rd_data <= mem[rd_ptr_bin[3:0]];
end
```

A read occurs only when:

```text
rd_en = 1
empty = 0
```

The lower four bits of `rd_ptr_bin` select the memory location.

After a successful read, the read pointer is incremented.

## Empty Flag

The `empty` flag indicates that there is no data available to read.

The design calculates the empty condition using:

```systemverilog
empty <= (rd_ptr_gray_next == wr_ptr_gray_sync);
```

When:

```text
empty = 1
```

the FIFO is considered empty and a read operation is prevented.

The condition for reading data is:

```systemverilog
rd_en && !empty
```

## Full Flag

The `full` flag indicates that the FIFO cannot accept another write.

The full condition is generated by comparing the next write pointer with the synchronized read pointer:

```systemverilog
full <= (wr_ptr_gray_next ==
         {~rd_ptr_gray_sync[4:3],
          rd_ptr_gray_sync[2:0]});
```

The upper Gray-code bits are inverted for full-condition detection.

When:

```text
full = 1
```

the FIFO prevents further write operations.

The condition for writing data is:

```systemverilog
wr_en && !full
```

## FIFO Operation Example

During verification, the testbench writes multiple data values into the FIFO, such as:

```text
C2
0A
B6
F0
E1
D2
C3
B4
A5
96
87
78
69
5A
4B
3C
2D
1E
0F
05
```

The data is written using the write clock and read using the independent read clock.

The write clock has a period of:

```text
10 ns
```

and the read clock has a period of:

```text
14 ns
```

This demonstrates FIFO operation with different clock frequencies.

## Testbench

The project includes a separate SystemVerilog testbench:

```text
testbench.sv
```

The testbench:

* Generates the write clock
* Generates the read clock
* Applies write-domain reset
* Applies read-domain reset
* Provides write enable
* Provides read enable
* Provides different input data
* Performs multiple FIFO write operations
* Performs multiple FIFO read operations
* Generates a VCD waveform
* Allows observation of FIFO pointers and status flags

The testbench generates the waveform using:

```systemverilog
$dumpfile("dump.vcd");
$dumpvars(0,Async_fifo_tb);
```

## Verification

The design was **simulated and functionally verified using EDA Playground**.

Different write and read operations were performed to verify the behavior of the FIFO.

The verification focuses on:

* FIFO reset operation
* Write operation
* Read operation
* Independent clock domains
* Write pointer increment
* Read pointer increment
* Binary-to-Gray conversion
* Pointer synchronization
* Empty flag operation
* Full flag operation
* Data transfer between clock domains
* Waveform behavior

## Waveform

The simulation waveform can be viewed using **EPWave on EDA Playground**.

Important signals observed during verification include:

```text
wr_clk
rd_clk
wr_rst
rd_rst
wr_en
rd_en
wr_data
rd_data
wr_ptr_bin
rd_ptr_bin
wr_ptr_gray
rd_ptr_gray
wr_ptr_gray_sync
rd_ptr_gray_sync
full
empty
```

Add your waveform screenshot to the repository as:

```text
images/waveform.png
```

Then display it in the README using:

```markdown
![Asynchronous FIFO Waveform](images/waveform.png)
```

## Project Structure

The GitHub repository contains the following files:

```text
Asynchronous-FIFO/
│
├── design.sv
├── testbench.sv
├── README.md
│
└── images/
    └── waveform.png
```

### `design.sv`

Contains the main **Asynchronous FIFO RTL design**, including:

* FIFO memory
* Read/write pointers
* Gray-code conversion
* Pointer synchronization
* Full flag logic
* Empty flag logic
* Read and write operations

### `testbench.sv`

Contains the **SystemVerilog testbench** used to simulate and functionally verify the FIFO on EDA Playground.

### `README.md`

Contains the project documentation, architecture, operation, verification details, and tool information.

### `images/waveform.png`

Contains the waveform screenshot generated during simulation.

## Tools Used

* **SystemVerilog** – RTL design and testbench development
* **EDA Playground** – Simulation and functional verification
* **EPWave** – Waveform visualization
* **VS Code** – Used to organize and store the SystemVerilog source files
* **GitHub** – Used to store and present the project

## Concepts Learned

This project helped in understanding and implementing:

* Asynchronous FIFO architecture
* Dual-clock design
* Clock-domain crossing
* FIFO memory organization
* Binary read/write pointers
* Extra pointer MSB
* Binary-to-Gray code conversion
* Two-stage synchronizers
* Metastability reduction
* Full condition detection
* Empty condition detection
* Sequential and combinational SystemVerilog logic
* `always_ff` blocks
* SystemVerilog testbench development
* Functional verification
* VCD waveform generation
* Waveform analysis

## Future Improvements

The project can be further improved by:

* Making FIFO depth and data width parameterized
* Adding SystemVerilog assertions
* Adding randomized testing
* Adding automatic pass/fail checking
* Adding dedicated overflow and underflow tests
* Performing RTL synthesis
* Performing timing and resource analysis

## Author

**Niraj Kale**

Electronics and Telecommunication Engineering

## Purpose

This project was developed as a **SystemVerilog / VLSI design project** to understand:

* Asynchronous FIFO design
* Dual-clock data transfer
* Clock-domain crossing
* Gray-code based pointer synchronization
* FIFO full and empty detection
* SystemVerilog RTL coding
* Testbench development
* Functional verification
* RTL simulation and waveform analysis
