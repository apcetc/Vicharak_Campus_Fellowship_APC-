# ShrikeFi 16-bit Multicycle CPU

A custom **16-bit multicycle CPU implemented in Verilog** on the FPGA fabric of the **Vicharak ShrikeFi development board**.

This project explores the fundamentals of processor design, including instruction fetching, register operations, arithmetic and logic execution, branching, memory access, and control sequencing. The initial demonstration runs a program stored in an internal instruction ROM to blink the FPGA's user LED.

## Overview

The CPU is designed as a compact educational processor with a three-state control sequence:

1. **FETCH** — Fetch an instruction from the instruction ROM.
2. **READ** — Read the required operands from the register file.
3. **EXECUTE** — Execute the instruction, update the destination register or memory, and determine the next program counter.

The processor uses a 16-bit instruction word, a 16-bit datapath, a small register file, and an internal data memory.

## Features

- Custom 16-bit processor architecture written in Verilog.
- Three-state multicycle control unit.
- Internal instruction ROM with a demonstration program.
- Register file with seven writable general-purpose registers (`R1`–`R7`).
- Register `R0` always reads as zero.
- Arithmetic and logical operations.
- Immediate-value loading and addition.
- Data-memory load and store instructions.
- Conditional branching and unconditional jumps.
- Output instruction for controlling the FPGA LED.
- Startup delay before CPU execution.
- Hardware demonstration using the FPGA fabric of the Vicharak ShrikeFi.

## Hardware Platform

| Component | Details |
|---|---|
| Development board | Vicharak ShrikeFi |
| FPGA | Renesas ForgeFPGA SLG47910 |
| Host microcontroller | ESP32-S3 |
| HDL | Verilog |
| Main clock | Board-provided FPGA clock |
| Demonstration output | FPGA user LED, GPIO16 |

**Important:** The CPU executes in the FPGA fabric. The ESP32-S3 is not used to execute the processor instructions in this design.

Refer to the official [ShrikeFi pinout documentation](https://vicharak-in.github.io/shrike/shrike_pinouts.html) for the board's FPGA and microcontroller connections.

## Architecture

```text
              +----------------------+
              |   Instruction ROM    |
              +----------+-----------+
                         |
                         v
              +----------------------+
              | Instruction Register |
              +----------+-----------+
                         |
                         v
              +----------------------+
              | Instruction Decoder  |
              +----------+-----------+
                         |
                         v
              +----------------------+
              |    Register File     |
              +----------+-----------+
                         |
                         v
              +----------------------+
              |         ALU          |
              +----------+-----------+
                         |
              +----------+-----------+
              |                      |
              v                      v
       +-------------+        +-------------+
       | Data Memory |        | Output Reg. |
       +-------------+        +------+------+
                                     |
                                     v
                              FPGA User LED

       Control Unit: FETCH -> READ -> EXECUTE
```

The control unit coordinates instruction fetching, operand reads, execution, register writes, memory operations, and program-counter updates.

## Instruction Set

The processor defines the following opcodes:

| Instruction | Operation |
|---|---|
| `NOP` | No operation |
| `ADD` | Add two register operands |
| `SUB` | Subtract one register operand from another |
| `AND` | Bitwise AND |
| `OR` | Bitwise OR |
| `XOR` | Bitwise XOR |
| `ADDI` | Add a sign-extended 6-bit immediate |
| `LDI` | Load a zero-extended 9-bit immediate |
| `LD` | Load a word from data memory |
| `ST` | Store a word in data memory |
| `JMP` | Jump to an absolute instruction address |
| `BEQ` | Branch if two operands are equal |
| `BNE` | Branch if two operands are not equal |
| `OUT` | Update the output register |
| `HLT` | Halt CPU execution |

The current implementation uses 16-bit instructions and a 5-bit program counter, allowing 32 instruction addresses.

## LED-Blinking Demonstration

The instruction ROM contains a program that repeatedly toggles the LED state.

The program:

1. Initializes `R1` to zero to represent the LED state.
2. Initializes `R2` to one for toggling the state.
3. Uses `XOR` to toggle `R1`.
4. Writes the state to the output register using `OUT`.
5. Executes nested countdown loops to create a visible delay.
6. Repeats the program continuously.

The startup counter holds the CPU in its initialization state for approximately **327.68 microseconds at a 50 MHz clock**, before instruction execution begins.

The actual blink rate depends on the clock frequency and the number of cycles spent executing each loop.


## Current Limitations

- The demonstration program exercises only a subset of the defined instruction set.
- The processor uses a small, fixed instruction ROM and a 5-bit program counter.
- Data memory contains 16 words.
- The design is intended as an educational processor, not a standards-compliant commercial CPU.

## Future Improvements

- Add a self-checking Verilog testbench.
- Verify each instruction with directed tests.
- Improve reset and initialization handling.
- Add debugging outputs for the program counter and register values.
- Explore FPGA resource utilization and maximum operating frequency.
- Extend the instruction set and improve the programming interface.
- Explore communication between the FPGA CPU and the ESP32-S3.

## References

- [Vicharak ShrikeFi Pinouts](https://vicharak-in.github.io/shrike/shrike_pinouts.html)
- [Vicharak Shrike Documentation](https://vicharak-in.github.io/shrike/)

## Author

**Annestio Piety Castanha**

Electronics and Telecommunication Engineering  
Goa College of Engineering

Interests: FPGA design, Verilog HDL, digital systems, and computer architecture.

---

This project is an independent learning project developed using the FPGA fabric of the Vicharak ShrikeFi development board.
