MIPS32 is a version of Microprocessor without Interlocked Pipeline Stages architecture which executes instructions
through five stage pipeline: IF(instruction set), ID(instruction decode), EX(execution), MEM(memory), and
WB(write back) stages. It uses Latches(registers) to store intermediate data between the stages to maintain data flow.
  
ALU functions were used with different addressing modes including Direct Register Addressing mode(RR), Register
Immediate Addressing mode(RM), Base Addressing mode and Relative Addressing mode.

The design code and the testbench code are present in folder *risc_pipeline.srcs* and further in sim_1/new and source_1/new.
