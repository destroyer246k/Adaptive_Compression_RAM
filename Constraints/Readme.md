# PINE S7 FPGA Constraints

## Overview

This directory contains the Xilinx Design Constraints (XDC) file for the **PINE S7 FPGA development board**, featuring the **AMD/Xilinx Spartan-7 XC7S15-FTGB196-1 FPGA**.

The constraints map the top-level RTL ports of `pine_s7_top` to the physical FPGA pins and configure the I/O standards and clock timing.

## Target Hardware

| Parameter | Configuration |
|---|---|
| Development Board | PINE S7 |
| FPGA Device | XC7S15-FTGB196-1 |
| FPGA Family | Spartan-7 |
| Package | FTGB196 |
| Speed Grade | -1 |
| System Clock | 100 MHz |
| Clock Period | 10 ns |
| I/O Standard | LVCMOS33 |
| I/O Voltage | 3.3 V |

## Pin Assignments

### 1. System Clock

| Signal | FPGA Pin | Frequency | Period |
|---|---|---|---|
| `osc_clk_100mhz` | G11 | 100 MHz | 10 ns |

The XDC file defines a 100 MHz clock using `create_clock`, with a 50% duty cycle.

### 2. Push Buttons

| RTL Signal | FPGA Pin | Description |
|---|---|---|
| `KEY_0` | B5 | Push button 0 |
| `KEY_3` | B3 | Push button 3 |

The buttons are active-low: their signals are high when idle and low when pressed.

### 3. Slide Switches

| Signal | FPGA Pin |
|---|---|
| `SLIDE_SW[0]` | A5 |
| `SLIDE_SW[1]` | B6 |
| `SLIDE_SW[2]` | F4 |
| `SLIDE_SW[3]` | C3 |
| `SLIDE_SW[4]` | C4 |
| `SLIDE_SW[5]` | A10 |
| `SLIDE_SW[6]` | B13 |
| `SLIDE_SW[7]` | C14 |
| `SLIDE_SW[8]` | D13 |
| `SLIDE_SW[9]` | F14 |
| `SLIDE_SW[10]` | G14 |
| `SLIDE_SW[11]` | H13 |
| `SLIDE_SW[12]` | D12 |
| `SLIDE_SW[13]` | E12 |
| `SLIDE_SW[14]` | F11 |
| `SLIDE_SW[15]` | H11 |

The 16 slide switches can be used as inputs for configuration, data entry, mode selection, and hardware testing.

### 4. LEDs

| Signal | FPGA Pin |
|---|---|
| `LED[0]` | F3 |
| `LED[1]` | E4 |
| `LED[2]` | D3 |
| `LED[3]` | D4 |
| `LED[4]` | C5 |
| `LED[5]` | A12 |
| `LED[6]` | A13 |
| `LED[7]` | B14 |
| `LED[8]` | D14 |
| `LED[9]` | E13 |
| `LED[10]` | F13 |
| `LED[11]` | H14 |
| `LED[12]` | J14 |
| `LED[13]` | C12 |
| `LED[14]` | E11 |
| `LED[15]` | F12 |

The 16 LEDs provide visual output for debugging, status indication, data monitoring, and verification of RTL functionality.

### 5. Seven-Segment Display

#### Segment Signals

| RTL Signal | FPGA Pin | Segment |
|---|---|---|
| `SIG_A` | G4 | A |
| `SIG_B` | H3 | B |
| `SIG_C` | J3 | C |
| `SIG_D` | L3 | D |
| `SIG_E` | K3 | E |
| `SIG_F` | H4 | F |
| `SIG_G` | J4 | G |
| `SIG_PD` | K4 | Decimal point |

#### Display Selection Signals

| RTL Signal | FPGA Pin |
|---|---|
| `SEL_DISP1` | H1 |
| `SEL_DISP2` | H2 |
| `SEL_DISP3` | F1 |
| `SEL_DISP4` | G1 |

The four display-selection signals support multiplexed operation of the four-digit seven-segment display. The RTL must implement the appropriate digit scanning and segment encoding.

**Note:** The active-high or active-low polarity of the display segments and digit enables must be verified against the board documentation.

## Configuration and Timing Constraints

### FPGA Configuration

```tcl
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
```

These properties configure the FPGA configuration-bank voltage settings for the board's 3.3 V configuration interface.

### Clock Constraint

```tcl
create_clock -add -name sys_clk_pin \
    -period 10.00 -waveform {0 5} \
    [get_ports {osc_clk_100mhz}]
```

This defines the primary clock as:

- Frequency: 100 MHz
- Period: 10 ns
- Rising edge: 0 ns
- Falling edge: 5 ns

### False-Path Constraints

```tcl
set_false_path -from [get_ports {SLIDE_SW[*] KEY_0 KEY_3}]
set_false_path -to [get_ports {LED[*] SIG_* SEL_DISP*}]
```

These constraints exclude specified asynchronous input paths and output paths from normal static timing analysis.

- **Input paths:** Slide switches and push buttons are treated as asynchronous human inputs.
- **Output paths:** LEDs and seven-segment display outputs have no external timing requirement specified in this file.

The design notes indicate that human inputs are already synchronized using two flip-flops (2-FF synchronizers).

**Important:** False paths do not synchronize signals or eliminate metastability. The RTL must implement proper synchronization for asynchronous inputs. The broad output false paths also suppress timing checks to the listed outputs, so ensure that this is appropriate for the design's timing requirements.

## Repository Structure

A suggested repository layout is:

```text
project/
├── constraints/
│   ├── pine_s7_top.xdc
│   └── README.md
├── rtl/
│   └── pine_s7_top.v
├── sim/
│   └── testbench.v
└── README.md
```

Adjust the filenames and directories to match the actual project.

## Usage in Vivado

1. Open the project in AMD Vivado.
2. Add the RTL source files.
3. Add `pine_s7_top.xdc` under **Constraints → Add Sources → Add or Create Constraints**.
4. Ensure the RTL top module is named `pine_s7_top`, or update the constraints to match the actual top-level port names.
5. Run **Synthesis**.
6. Run **Implementation** and review any pin-assignment, I/O, or timing warnings.
7. Generate the bitstream and program the PINE S7 board.

## Source

The pin assignments are based on the manufacturer's PINE S7 master constraints file:

[PINE S7 MASTER.xdc — FPGA Tech Solution](https://github.com/fpgatechsolution/PINE-S7)

Only the pins used by this design are included.

## Notes

- The RTL top-level port names must exactly match the names referenced in the XDC file.
- All assigned user I/O pins use `LVCMOS33`.
- The clock must be constrained correctly for reliable timing analysis.
- Verify board-specific electrical requirements before connecting external hardware.
- Review Vivado DRC and timing reports before generating the final bitstream.
