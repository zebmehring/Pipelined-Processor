# Pipelined-Processor
A Verilog implementation of a 5-stage scalar pipelined processor, created as part of a final project for Computer Architecture (EENG 467) at Yale. Auxillary modules such as memory and testbench initialization were created by Jakub Szefer.

The design provided is a five-stage pipeline that accesses different memories for instructions and data. It supports the following RISC-V instructions: lw, sw, addi, slti, add, sub, slt, beq, blt, and bge. The five stages are: instruction fetch, instruction decode, execute,
memory access, and writeback.
