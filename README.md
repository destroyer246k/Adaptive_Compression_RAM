# Adaptive Compression-Aware Memory Controller for Resource-Constrained FPGAs

An FPGA-based memory controller that adaptively compresses data blocks using **Run-Length Encoding (RLE), Delta4, and Delta8 compression** to reduce storage requirements while preserving lossless data reconstruction.

## Overview

This project implements an adaptive compression-aware memory controller using Verilog HDL and Xilinx Vivado. It analyzes input data blocks, evaluates different compression techniques, selects the most storage-efficient representation, and manages compressed data and metadata in memory.

The design targets the **PINE S7 FPGA development board**, featuring the Xilinx Spartan-7 `XC7S15FTGB196-1`.

## Key Features

- **Adaptive Compression:** Selects the most efficient encoding among RAW, DELTA4, DELTA8, and RLE.
- **Run-Length Encoding (RLE):** Compresses consecutive repeated values into symbol-count pairs.
- **Delta Compression:** Encodes differences between consecutive bytes using 4-bit or 8-bit signed deltas.
- **Adaptive Mode Selection:** Compares encoded sizes and selects the representation requiring the least storage.
- **Lossless Decompression:** Reconstructs original data from supported compressed formats.
- **Memory Management:** Uses compressed data RAM and metadata RAM to store encoded blocks and their associated information.
- **Modular RTL Design:** Implements separate compression, packing, selection, formatting, memory, and controller modules.
- **Verification:** Includes individual testbenches for compression modules, round-trip reconstruction, memory interfaces, and write-path integration.

## Compression Modes

| Mode | Encoding | Storage for a 16-byte block |
|---|---|---:|
| `00` | RAW | 128 bits |
| `01` | DELTA4 | 68 bits |
| `10` | DELTA8 | 128 bits |
| `11` | RLE | 16 bits per run |

The controller compares the estimated encoded sizes and selects a suitable representation. DELTA4 is particularly effective for slowly varying data, while RLE works well for repeated values.

## Architecture

```text
          Input Data Block
             128 bits
                 |
        +--------+--------+
        |                 |
   Delta Analyzer    RLE Compressor
        |                 |
   +----+----+       RLE Storage
   |         |           Packer
 DELTA4    DELTA8          |
 Packer    Packer          |
   |         |             |
   +---------+-------------+
                 |
          Adaptive Selector
                 |
        Compression Formatter
                 |
           Write Controller
                 |
          +------+------+
          |             |
     Compressed      Metadata
       Data RAM        RAM
```

## Technology Stack

- **HDL:** Verilog
- **FPGA:** Xilinx Spartan-7 `XC7S15FTGB196-1`
- **Development Board:** PINE S7
- **EDA Tool:** Xilinx Vivado 2025.1
- **Verification:** RTL simulation and module-level testbenches

## Verification

The design was developed and tested incrementally. Individual testbenches were used to verify the RLE and delta compressors/decompressors, adaptive selection, packing formats, metadata storage, compressed data storage, and write-path integration.

The module-level and write-path tests passed with zero reported errors. Full end-to-end integration and FPGA implementation results should be reported separately according to the final simulation and hardware validation results.

## Potential Applications

- Memory optimization in resource-constrained FPGA systems
- Embedded data buffering
- Lossless storage of repetitive or slowly varying data
- Compression-aware hardware memory architectures
- FPGA-based data acquisition and processing systems

## Future Improvements

- Variable-length physical memory allocation and packed storage
- Read controller and automatic decompression routing
- Performance evaluation using LUT, flip-flop, BRAM, latency, and throughput metrics
- Optimization for larger data blocks and streaming applications

## Author

**Vishwas Patel**  
Electronics and Telecommunication Engineering

---

*This project explores adaptive lossless compression as a hardware-level technique for improving effective memory utilization on resource-constrained FPGAs.*
