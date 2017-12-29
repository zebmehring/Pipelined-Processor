/*
 *
 * Processor pipeline module
 *
 */

`define OPCODE 6:0
`define RD     11:7
`define FUNCT3 14:12
`define RS1    19:15
`define RS2    24:20
`define FUNCT7 31:25
`define IMM    31:20

module pipeline
#(
  parameter WIDTH = 32,  // memory width for inst. and data memories
  parameter NREGS = 32   // number of registers
)
(
  input  wire                 clock,
  output wire [WIDTH-1:0]     inst_data,     // instruction memory signals
  output wire [WIDTH-1:0]     inst_rdaddress,
  output wire                 inst_rden,
  output wire [WIDTH-1:0]     inst_wraddress,
  output wire                 inst_wren,
  input  wire [WIDTH-1:0]     inst_q,
  output wire [WIDTH-1:0]     data_data,     // data memory signals
  output wire [WIDTH-1:0]     data_rdaddress,
  output wire                 data_rden,
  output wire [WIDTH-1:0]     data_wraddress,
  output wire                 data_wren,
  input  wire [WIDTH-1:0]     data_q,
  output wire [WIDTH-1:0]     debug1,        // debug signals
  output wire [WIDTH-1:0]     debug2,
  output wire [WIDTH-1:0]     debug3,
  output wire [WIDTH-1:0]     debug4,
  output wire [WIDTH-1:0]     debug5,
  output wire [WIDTH-1:0]     debug6
);

/*******************************************************************
* Global Parameters and Initializations
*******************************************************************/

// register file
reg [WIDTH-1:0] regs [NREGS-1:0];

// pipeline buffers to propegate instruction
reg [WIDTH-1:0] IF_buf  = 0;
reg [WIDTH-1:0] ID_buf  = 0;
reg [WIDTH-1:0] EX_buf  = 0;
reg [WIDTH-1:0] MEM_buf = 0;

// initializes the registers to 0
integer i;
initial 
begin
    for(i = 0 ; i < NREGS; i = i + 1)
    begin
        regs[i] = 0;
    end
end

// debugging info
assign debug1 = regs[6];
assign debug2 = regs[5];
assign debug3 = regs[4];
assign debug4 = regs[3];
assign debug5 = regs[2];
assign debug6 = regs[1];

/*******************************************************************
* Fetch Stage
*   * detect branch hazards and generate stall
*   * update the PC
*   * fill the IF buffer
*******************************************************************/

// null instruction used for stalling
parameter NOP = 32'b00000000000000000000000000000000;

// stores the address of the next instruction
reg [WIDTH-1:0] pc = 0;
assign inst_rdaddress = pc;

// stall control (branch hazards)
reg branch_stall = 0;

// stores the instruction address
reg [WIDTH-1:0] pc_IF = 0;

// enable writing to the IF buffer if there are no data hazard stalls
wire IF_buf_en;
assign IF_buf_en = !(in_progress[IF_buf[`RS1]] || (((IF_buf[`OPCODE] == R) || (IF_buf[`OPCODE] == S) || (IF_buf[`OPCODE] == B)) && in_progress[IF_buf[`RS2]]));

// enable reading from memory if there are no data hazard stalls
assign inst_rden = !(in_progress[IF_buf[`RS1]] || (((IF_buf[`OPCODE] == R) || (IF_buf[`OPCODE] == S) || (IF_buf[`OPCODE] == B)) && in_progress[IF_buf[`RS2]]));

// fetch cycle
always @(posedge clock)
begin
    // stall if the next instruction is a branch
    if(!data_stall && !branch_stall && (inst_q[`OPCODE] == B)) branch_stall <= 1;

    // if we're in a data hazard, don't refresh the buffer
    if(!IF_buf_en) IF_buf <= IF_buf;
    // if we're in a branch hazard, send a NOP
    else if(branch_stall) IF_buf <= NOP;
    // if the branch was taken, stall for one cycle
    else if(branch_taken)
    begin
      IF_buf <= NOP;
      branch_taken <= 0;
    end
    // otherwise update the buffer with the value from memory
    else IF_buf <= inst_q;
    
    // don't increment the pc if we're in a hazard or if the next instruction will generate a branch hazard
    if(!(branch_stall || (inst_q[`OPCODE] == B) || data_stall)) pc <= pc + 1;

    // propagate the instruction address
    pc_IF <= pc - 1;
end

/*******************************************************************
* Decode Stage
*   * mark potential data hazards
*   * detect data hazards and generate stall
*   * get data from the registers
*   * concatenate the immediate
*   * set the operation for the ALU
*******************************************************************/

// opcode formats
parameter L = 7'b0000011;
parameter I = 7'b0010011;
parameter S = 7'b0100011;
parameter R = 7'b0110011;
parameter B = 7'b1100011;
// ALUOp signals
parameter ADD = 2'b00;
parameter SUB = 2'b01;
parameter LT  = 2'b10;
parameter GE  = 2'b11;

// stores the value from register RS1
reg [WIDTH-1:0] rd_data_1 = 0;
// stores the value from register RS2
reg [WIDTH-1:0] rd_data_2 = 0;
// stores the immediate value provided
reg [WIDTH-1:0] imm = 0;
// stores the code for ALU operations
reg [1:0] alu_op = 0;
// stores the instruction address
reg [WIDTH-1:0] pc_ID = 0;

// boolean array to track potential data hazards
reg [WIDTH-1:0] in_progress = 0;

// detect if the next instruction is a data hazard
wire data_stall;
assign data_stall = (in_progress[IF_buf[`RS1]] || (((IF_buf[`OPCODE] == R) || (IF_buf[`OPCODE] == S) || (IF_buf[`OPCODE] == B)) && in_progress[IF_buf[`RS2]]));

// decode cycle
always @(posedge clock)
begin
    // mark destination registers to be in use
    if((!branch_stall) && ((IF_buf[`OPCODE] == L) || (IF_buf[`OPCODE] == I) || (IF_buf[`OPCODE] == R))) in_progress[IF_buf[`RD]] <= 1;

    // refresh the buffer if there are no data hazards, otherwise, send a NOP
    ID_buf <= data_stall ? NOP : IF_buf;

    // propagate the instruction address
    pc_ID <= pc_IF;

    // get the value of RS1, or 0 (NOP) on a data hazard
    rd_data_1 <= data_stall ? 0 : regs[IF_buf[`RS1]];
    // get the value of RS2, or 0 (NOP) on a data hazard
    rd_data_2 <= data_stall ? 0 : regs[IF_buf[`RS2]];
    // get the value of the immediate (and sign extend), or 0 (NOP) on a data hazard
    if(data_stall) imm <= 0;
    else if(IF_buf[`OPCODE] == S) imm <= {{20{IF_buf[31]}},IF_buf[`FUNCT7],IF_buf[`RD]};
    else if(IF_buf[`OPCODE] == B) imm <= {{20{IF_buf[31]}},IF_buf[7],IF_buf[30:25],IF_buf[11:8],1'b0};
    else imm <= {{20{IF_buf[31]}},IF_buf[`IMM]};

    // set the alu controls based on the instruction, or ADD on a data hazard
    case(IF_buf[`OPCODE])
        L: alu_op <= ADD;
        I: alu_op <= (IF_buf[`FUNCT3] == 3'b000) ? ADD : LT;
        S: alu_op <= ADD;
        R: begin
            case(IF_buf[`FUNCT3])
                3'b000: alu_op <= (IF_buf[`FUNCT7]) ? SUB : ADD;
                3'b010: alu_op <= LT;
            endcase
        end
        B: begin
            case(IF_buf[`FUNCT3])
                3'b000: alu_op <= SUB;
                3'b100: alu_op <= LT;
                3'b101: alu_op <= GE;
            endcase
        end
        default: alu_op <= ADD;
    endcase
end

/*******************************************************************
* Execute Stage
*   * set inputs to the data memory
*   * perform an arithmetic computation on ALU inputs
*******************************************************************/

// connects the register holding the value in RS1 to the ALU
wire [WIDTH-1:0] alu_1;
assign alu_1 = rd_data_1;
// connects the register holding the value in RS2 or the immediate to the ALU
wire [WIDTH-1:0] alu_2;
assign alu_2 = ((ID_buf[`OPCODE] == B) || (ID_buf[`OPCODE] == R)) ? rd_data_2 : imm;

// stores the value of the data in RS2
reg [WIDTH-1:0] mem_data_in = 0;
// stores the result of the ALU computation
reg [WIDTH-1:0] alu_result = 0;
// stores the value of the potential branch location
reg [WIDTH-1:0] branch_loc = 0;

// execute cycle
always @(posedge clock)
begin
    // fill the next buffer
    EX_buf <= ID_buf;
    // propagate the value in RS2
    mem_data_in <= rd_data_2;
    // propagate the immediate value
    branch_loc <= imm + pc_ID;
    // do the ALU computation
    case(alu_op)
        ADD: alu_result <= alu_1 + alu_2; 
        SUB: alu_result <= alu_1 - alu_2;
        LT:  alu_result <= alu_1 < alu_2;
        GE:  alu_result <= alu_1 >= alu_2;
    endcase
end

/*******************************************************************
* Memory Stage
*   * read data/write results to memory based on the instruction
*   * end branch stalls
*******************************************************************/

// stores the ALU result
reg [WIDTH-1:0] alu_out = 0;
// stores whether or not the branch was taken
reg             branch_taken = 0;

// enable memory reading on load instructions
assign data_rden = (EX_buf[`OPCODE] == L);
// enable memory writing on store instrucitons
assign data_wren = (EX_buf[`OPCODE] == S);
// connect the computed address to the memory
assign data_rdaddress = alu_result;
assign data_wraddress = alu_result;
// connect the data from RS2 to the memory
assign data_data = mem_data_in;

// memory cycle
always @(posedge clock)
begin
    // fill the next buffer
    MEM_buf <= EX_buf;
    // propagate the ALU result
    alu_out <= alu_result;
    // update the pc after a branch instruction and end the stall
    if(EX_buf[`OPCODE] == B) 
    begin
      pc <= (EX_buf[`FUNCT3] ? alu_result : !alu_result) ? branch_loc : pc + 1;
      branch_taken <= (EX_buf[`FUNCT3] ? alu_result : !alu_result);
      branch_stall <= 0;
    end
    
end

/*******************************************************************
* Write Back Stage
*   * write appropriate values back to the registers
*   * end data stalls
*******************************************************************/

// write back cycle
always @(posedge clock)
begin
  // write back to registers on L or I or R instructions
  if((MEM_buf[`OPCODE] == L) || (MEM_buf[`OPCODE] == I) || (MEM_buf[`OPCODE] == R)) regs[MEM_buf[`RD]] <= (MEM_buf[`OPCODE] == L) ? data_q : alu_out;
  // free up the destination register
  in_progress[MEM_buf[`RD]] <= 0;
end

endmodule
