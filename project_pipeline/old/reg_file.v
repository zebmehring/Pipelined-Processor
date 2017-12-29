module reg_file
#(
  parameter WIDTH = 32,
  parameter NREGS = 32
)
(
  input  wire                    clock,
  input  wire                    wr_en,
  input  wire [WIDTH-1:0]        wr_data,
  input  wire [CLOG2(WIDTH)-1:0] wr_addr,
  input  wire [CLOG2(WIDTH)-1:0] rs1,
  input  wire [CLOG2(WIDTH)-1:0] rs2,
  output wire [WIDTH-1:0]        rd_data_1,
  output wire [WIDTH-1:0]        rd_data_2
);

reg [WIDTH-1:0] regs [NREGS-1:0];

assign rd_data_1 = regs[rs1];
assign rd_data_2 = regs[rs2];
always @(posedge clock) regs[wr_addr] <= (wr_en) ? wr_data : regs[wr_addr];

endmodule