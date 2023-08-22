`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/28/2023 01:59:52 PM
// Design Name: 
// Module Name: pipe_mips_32
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pipe_mips_32( clk1,clk2);
input clk1,clk2;

parameter RR_ALU=3'b000,RM_ALU=3'b001,LOAD=3'b010,STORE=3'b011,BRANCH=3'b100,HALT=3'b101;
parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011,SLT=6'b000100,MUL=6'b000101,   //RR_ALU
 HLT=6'b111111,                                                                                    // HALT
 LW=6'b001000,SW=6'b001001,                                                                        // LOAD , STORE     
 ADDI=6'b001010, SUBI=6'b001011,SLTI=6'b001100,                                                    //RM_ALU
 BNEQZ=6'b001101, BEQZ=6'b001110;                                                                  //BRANCH


reg [31:0] PC;    
reg [31:0] IF_ID_IR,   IF_ID_NPC;
reg [31:0] ID_EX_IR,    ID_EX_A,    ID_EX_B,    ID_EX_IMM,  ID_EX_NPC;
reg [2:0] ID_EX_TYPE;
reg [31:0] EX_MEM_IR,   EX_MEM_ALU_OUT,         EX_MEM_B,   EX_MEM_COND;
reg [2:0] EX_MEM_TYPE;
reg [31:0] MEM_WB_IR,   MEM_WB_ALU_OUT,         MEM_WB_LMD;
reg [2:0] MEM_WB_TYPE;

reg HALTED,TAKEN_BRANCH;

reg [31:0] reg_bank [31:0];
//reg [31:0] data_mem [511:0];
reg [31:0] inst_mem [1023:0];

//////////////////////////////////////////////////////////////////// STAGE 1 INSTRUCTION FETCH ////////////////////////////////////////////////////////////////////////
always@(posedge clk1)       
begin
    if(~HALTED)
    begin
        if((EX_MEM_COND==1'b1 && EX_MEM_IR[31:26]==BEQZ) || (EX_MEM_COND==1'b0 && EX_MEM_IR[31:26]==BNEQZ)) 
        begin
            IF_ID_IR<=inst_mem[EX_MEM_ALU_OUT];
            IF_ID_NPC<=EX_MEM_ALU_OUT+1;
            PC<=EX_MEM_ALU_OUT+1;
            TAKEN_BRANCH<=1'B1;        
        end
        else
        begin
            IF_ID_IR<=inst_mem[PC];
            IF_ID_NPC<=PC+1;
            PC<=PC+1;
        end
    end
end

//////////////////////////////////////////////////////////////////// STAGE 2 INSTRUCTION DECODE ////////////////////////////////////////////////////////////////////////

always@(posedge clk1)
begin
    if(~HALTED)
    begin
        ID_EX_IR<=IF_ID_IR;
        ID_EX_NPC<=IF_ID_NPC;
        ID_EX_IMM<={{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};
        if(IF_ID_IR[25:21]==5'b00000)
            ID_EX_A<=5'b00000;
        else
            ID_EX_A<=reg_bank[IF_ID_IR[25:21]];
        
        if(IF_ID_IR[20:16]==5'b00000)
            ID_EX_B<=5'b00000;
        else
            ID_EX_B<=reg_bank[IF_ID_IR[20:16]];
                    
    case(IF_ID_IR[31:26])
    ADD,SUB,AND,OR,SLT,MUL: ID_EX_TYPE<=RR_ALU;
    ADDI,SUBI,SLTI:         ID_EX_TYPE<=RM_ALU;
    LW:                     ID_EX_TYPE<=LOAD;
    SW:                     ID_EX_TYPE<=STORE;               
    BNEQZ,BEQZ:             ID_EX_TYPE<=BRANCH;
    HLT:                    ID_EX_TYPE<=HALT;
    default:                ID_EX_TYPE<=HALT;  
    endcase
    end
end

//////////////////////////////////////////////////////////////////// STAGE 3 EXECUTE /////////////////////////////////////////////////////////////////

always@(posedge clk1)
begin
if(~HALTED)
begin
EX_MEM_IR<=ID_EX_IR;
EX_MEM_TYPE<=ID_EX_TYPE;
TAKEN_BRANCH<=0;

case(ID_EX_TYPE)
RR_ALU:begin
    case(ID_EX_IR[31:26])
     ADD: EX_MEM_ALU_OUT <= ID_EX_A + ID_EX_B;
     SUB: EX_MEM_ALU_OUT <= ID_EX_A - ID_EX_B; 
     AND: EX_MEM_ALU_OUT <= ID_EX_A & ID_EX_B; 
     OR: EX_MEM_ALU_OUT  <= ID_EX_A | ID_EX_B; 
     SLT: EX_MEM_ALU_OUT <= ID_EX_A < ID_EX_B; 
     MUL: EX_MEM_ALU_OUT <= ID_EX_A * ID_EX_B; 
    default:    EX_MEM_ALU_OUT<= 32'hxxxxxxxx;    
    endcase
    end

RM_ALU:begin
    case(ID_EX_IR[31:26])
     ADDI: EX_MEM_ALU_OUT <= ID_EX_A + ID_EX_IMM;
     SUBI: EX_MEM_ALU_OUT <= ID_EX_A - ID_EX_IMM; 
     SLTI: EX_MEM_ALU_OUT <= ID_EX_A < ID_EX_IMM; 
    default:    EX_MEM_ALU_OUT<= 32'hxxxxxxxx;    
    endcase
    end

LOAD,STORE:begin
    EX_MEM_ALU_OUT<=ID_EX_B+ID_EX_IMM;
    EX_MEM_B<=ID_EX_B;
end

BRANCH:begin
    EX_MEM_ALU_OUT<=ID_EX_IMM+ID_EX_NPC;
    EX_MEM_COND<=(ID_EX_A==0);
end

endcase
end
end

/////////////////////////////////////////////////////////////////// STAEG 4 MEMORY /////////////////////////////////////////////////////////////////

always@(posedge clk1)
begin
MEM_WB_IR<=EX_MEM_IR;
MEM_WB_TYPE<=EX_MEM_TYPE;

case(EX_MEM_TYPE)
 LOAD:               MEM_WB_LMD<=inst_mem[EX_MEM_ALU_OUT];
 
 RR_ALU,RM_ALU:      MEM_WB_ALU_OUT<=EX_MEM_ALU_OUT;
 
 STORE:begin
 if(~TAKEN_BRANCH)
       EX_MEM_B<=inst_mem[EX_MEM_ALU_OUT];
end
endcase
end

/////////////////////////////////////////////////////////////////// STAEG 5 WRITE BACK /////////////////////////////////////////////////////////////////

always@(posedge clk1)
begin
if(~TAKEN_BRANCH)
begin
case(MEM_WB_TYPE)
RR_ALU:         reg_bank[MEM_WB_IR[15:11]]<= MEM_WB_ALU_OUT;
RM_ALU:         reg_bank[MEM_WB_IR[20:16]]<= MEM_WB_ALU_OUT;
LOAD:           reg_bank[MEM_WB_IR[20:16]]<= MEM_WB_LMD;
HALT:           HALTED                    <= 1'b1;
endcase
end
end
endmodule












//module pipe_mips_32 (clk1, clk2);
//	input clk1, clk2;
//	reg [31:0] PC, IF_ID_IR, IF_ID_NPC;
//	reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
//	reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;
//	reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
//	reg EX_MEM_cond;
//	reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
//	reg [31:0] Reg [0:31];
//	reg [31:0] Mem [0:1023];

//	parameter ADD = 6'b000000, SUB = 6'b000001, AND = 6'b000010, OR = 6'b000011, SLT = 6'b000100, MUL = 6'b000101, HLT = 6'b111111, LW = 6'b001000, SW = 6'b001001, ADDI = 6'b001010, SUBI = 6'b001011, SLTI = 6'b001100, BNEQZ = 6'b001101, BEQZ = 6'b001110;
//	parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011, BRANCH = 3'b100, HALT = 3'b101;
//	reg HALTED;
//	reg TAKEN_BRANCH;

////////////////////////////////////////////////////////////// Instruction Fetch /////////////////////////////////////////////////////////////
  
//	always @(posedge clk1) 
//	begin
//		if (HALTED == 0)
//		begin
//			if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) || ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0)))
//			begin
//				IF_ID_IR <= #2 Mem[EX_MEM_ALUOut];
//				TAKEN_BRANCH <= #2 1'b1;
//				IF_ID_NPC <= #2 EX_MEM_ALUOut + 1;
//				PC <= #2 EX_MEM_ALUOut + 1;
//			end
//			else
//			begin
//				IF_ID_IR <= #2 Mem[PC];
//				IF_ID_NPC <= #2 PC + 1;
//				PC <= #2 PC + 1;
//			end
//		end
//	end
 
////////////////////////////////////////////////////////////// Instruction Decode /////////////////////////////////////////////////////////////

//	always @(posedge clk2) // ID stage
//	begin
//		if (HALTED == 0)
//		begin
//			if (IF_ID_IR[25:21] == 5'b00000)
//				ID_EX_A <= 0;
//			else
//				ID_EX_A <= #2 Reg[IF_ID_IR[25:21]]; // "rS"
      
//			if (IF_ID_IR[20:16] == 5'b00000)
//				ID_EX_B <= 0;
//			else
//				ID_EX_B <= #2 Reg[IF_ID_IR[20:16]]; // "rt"
        
//			ID_EX_NPC <= #2 IF_ID_NPC;
//			ID_EX_IR <= #2 IF_ID_IR;
//			ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};
      
//			case (IF_ID_IR[31:26])
//				ADD, SUB, AND, OR, SLT, MUL: ID_EX_type <= #2 RR_ALU;
//				ADDI, SUBI, SLTI: ID_EX_type <= #2 RM_ALU;
//				LW: ID_EX_type <= #2 LOAD;
//				SW: ID_EX_type <= #2 STORE;
//				BNEQZ, BEQZ: ID_EX_type <= #2 BRANCH;
//				HLT: ID_EX_type <= #2 HALT;
//				default: ID_EX_type <= #2 HALT;
//			endcase
//		end
//	end

////////////////////////////////////////////////////////////// Execution stage /////////////////////////////////////////////////////////////

//	always @(posedge clk1) 
//	begin
//		if (HALTED == 0)
//		begin
//			EX_MEM_type <= #2 ID_EX_type;
//			EX_MEM_IR <= #2 ID_EX_IR;
//			TAKEN_BRANCH <= #2 0;
      
//			case (ID_EX_type)
//				RR_ALU:
//				begin
//					case (ID_EX_IR[31:26]) // "opcode"
//						ADD: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;
//						SUB: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;
//						AND: EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
//						OR: EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
//						SLT: EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_B;
//						MUL: EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
//						default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
//					endcase
//				end
//				RM_ALU:
//				begin
//					case (ID_EX_IR[31:26])
//						ADDI: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
//						SUBI: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
//						SLTI: EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_Imm;
//						default: EX_MEM_ALUOut <= #2 32'hxXXXXXXX;
//					endcase
//				end
//			endcase
//		end
//	end

////////////////////////////////////////////////////////////// Memory stage /////////////////////////////////////////////////////////////

//	always @(posedge clk2)
//	begin
//		if (HALTED == 0)
//		begin
//			MEM_WB_type <= #2 EX_MEM_type;
//			MEM_WB_IR <= #2 EX_MEM_IR;
      
//			case (EX_MEM_type)
//				RR_ALU, RM_ALU: MEM_WB_ALUOut <= #2 EX_MEM_ALUOut;
//				LOAD: MEM_WB_LMD <= #2 Mem[EX_MEM_ALUOut];
//				STORE: if (TAKEN_BRANCH == 0) Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B;
//			endcase
//		end
//	end

////////////////////////////////////////////////////////////// Write Back /////////////////////////////////////////////////////////////

//	always @(posedge clk1)
//	begin
//		if (TAKEN_BRANCH == 0)
//		begin
//			case (MEM_WB_type)
//				RR_ALU: Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut; // "rd"
//				RM_ALU: Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut; // "rt"
//				LOAD: Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD; // "xt"
//				HALT: HALTED <= #2 1'b1;
//			endcase
//		end
//	end
//endmodule
