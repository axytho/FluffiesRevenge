//Module: CPU
//Function: CPU is the top design of the processor
//Inputs:
//	clk: main clock
//	arst_n: reset 
// 	enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// 	ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// 	ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory
//Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[31:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[31:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [31:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[31:0]  rdata_ext_2

   );

wire              zero_flag, zero_flag_in_pipeline;
wire [      31:0] branch_pc,updated_pc,current_pc,jump_pc,
                  instruction, instruction_in_pipeline, instruction_in_pipeline_2, instruction_in_pipeline_3, instruction_in_pipeline_4, updated_pc_in_pipeline, updated_pc_in_pipeline_2, regfile_data_1_in_pipeline, regfile_data_2_in_pipeline,
                  branch_pc_in_pipeline, jump_pc_in_pipeline;
wire [       1:0] alu_op;
wire [       3:0] alu_control, alu_control_in_pipeline;
wire              reg_dst, reg_dst_in_pipeline, reg_dst_in_pipeline_2, reg_dst_in_pipeline_3,  branch,mem_read,mem_2_reg, reg_write, reg_write_in_pipeline, reg_write_in_pipeline_2, reg_write_in_pipeline_3, 
                  mem_write,alu_src,  jump, branch_in_pipeline, mem_read_in_pipeline, mem_2_reg_in_pipeline, mem_write_in_pipeline,alu_src_in_pipeline,   jump_in_pipeline,
                  mem_write_in_pipeline_2, mem_2_reg_in_pipeline_2, mem_2_reg_in_pipeline_3;
wire [       4:0] regfile_waddr;
wire [      31:0] regfile_wdata, dram_data, dram_data_in_pipeline,alu_out, alu_out_in_pipeline, alu_out_in_pipeline_2,
                  regfile_data_1,regfile_data_2,
                  alu_operand_2,instruction_in_mux;
 

wire signed [31:0] immediate_extended_in_pipeline, immediate_extended;

assign immediate_extended_in_pipeline = $signed(instruction_in_pipeline_2[15:0]);

wire memForward,forwardA,forwardB,data_stall,stall,control_stall, control_stall_ID,control_stall_EX,enable_pc, enable_fetch;
wire [31:0] alu_bypassing,alu_operand_1,alu_operand_B;

wire branch_in_mux,mem_read_in_mux,mem_2_reg_in_mux,mem_write_in_mux,reg_write_in_mux;
wire jump_in_mux;
wire [4:0] destination_addr,second_operand;

wire we_buffer,post_jump,hit_buffer,pre_jump;
wire [31:0] current_pc_IFID, current_pc_IDEX,next_pc, target;

assign control_stall_ID = jump_in_pipeline | branch_in_pipeline;
assign control_stall_EX = branch           | jump ;
assign control_stall = control_stall_ID | control_stall_EX;
assign stall = data_stall | control_stall; 
assign enable_fetch = enable & (~data_stall);
assign enable_pc = enable & (~data_stall); //temporarily disable registers to stall


pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk                   ),
   .arst_n    (arst_n                ),
//   .branch_pc (branch_pc             ),
   .jump_pc   (jump_pc               ),
 //  .zero_flag (zero_flag             ),
 //  .branch    (branch                ),
   .jump      (jump                  ),
 //  .revert    (control_stall_ID      ),
   .current_pc(current_pc            ),
   .enable    (enable_pc             ), //don't update if stall 
   .updated_pc(updated_pc_in_pipeline)
);


branch_information_buffer buffer(
   .clk(clk),
   .nrst(arst_n),
   .re(1'b1), 
   .we(we_buffer), 
   .r_addr(current_pc),   
   .w_addr(current_pc_IDEX),
   .n_tar(target),
   .n_pre(post_jump),
   .o_tar(next_pc),
   .hit(hit_buffer),
   .pre(pre_jump)
);

sram #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction_in_mux   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);


mux_2 #(
   .DATA_W(32)
) instruction_control_stall_mux (
   .input_a (32'b0                  ), 
   .input_b (instruction_in_mux     ),
   .select_a(control_stall          ),
   .mux_out (instruction_in_pipeline)
);



reg_arstn_en	#(.DATA_W(32))
instruction_pipe (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (instruction_in_pipeline),
    .en    (enable_fetch),
    .dout  (instruction_in_pipeline_2)
);

reg_arstn_en	#(.DATA_W(32))
updated_pc_pc_plus_4 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (updated_pc_in_pipeline),
    .en    (enable_fetch),
    .dout  (updated_pc_in_pipeline_2)
);





control_unit control_unit(
   .opcode   (instruction_in_pipeline_2[31:26]),
   .reg_dst  (reg_dst_in_pipeline           ),
   .branch   (branch_in_mux                 ),
   .mem_read (mem_read_in_mux               ),
   .mem_2_reg(mem_2_reg_in_mux              ),
   .alu_op   (alu_op                        ),
   .mem_write(mem_write_in_mux              ),
   .alu_src  (alu_src_in_pipeline           ),
   .reg_write(reg_write_in_mux              ),
   .jump     (jump_in_mux                   )
);


mux_2 #(
   .DATA_W(1)
) branch_stall_mux (
   .input_a (1'b0               ), 
   .input_b (branch_in_mux      ),
   .select_a(data_stall         ),
   .mux_out (branch_in_pipeline )
);



mux_2 #(
   .DATA_W(1)
) mem_read_stall_mux (
   .input_a (1'b0                ), 
   .input_b (mem_read_in_mux     ),
   .select_a(data_stall               ),
   .mux_out (mem_read_in_pipeline)
);

mux_2 #(
   .DATA_W(1)
) mem_2_reg_stall_mux (
   .input_a (1'b0                  ), 
   .input_b (mem_2_reg_in_mux      ),
   .select_a(data_stall                 ),
   .mux_out (mem_2_reg_in_pipeline )
);

mux_2 #(
   .DATA_W(1)
) mem_write_stall_mux (
   .input_a (1'b0                  ), 
   .input_b (mem_write_in_mux      ),
   .select_a(data_stall                 ),
   .mux_out (mem_write_in_pipeline )
);


mux_2 #(
   .DATA_W(1)
) reg_write_stall_mux (
   .input_a (1'b0                  ), 
   .input_b (reg_write_in_mux      ),
   .select_a(data_stall            ),
   .mux_out (reg_write_in_pipeline )
);

mux_2 #(
   .DATA_W(1)
) jump_stall_mux (
   .input_a (1'b0                  ), 
   .input_b (jump_in_mux           ),
   .select_a(data_stall            ),
   .mux_out (jump_in_pipeline      )
);



alu_control alu_ctrl(
   .function_field (instruction_in_pipeline_2[5:0]),
   .alu_op         (alu_op          ),
   .alu_control    (alu_control_in_pipeline     )
);


mux_2 #(
   .DATA_W(5)
) regfile_dest_mux (
   .input_a (instruction[15:11]), //instruction being the instruction loaded 5 cycles ago.
   .input_b (instruction[20:16]),
   .select_a(reg_dst          ),
   .mux_out (regfile_waddr     )
);





register_file #(
   .DATA_W(32)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(reg_write         ),
   .raddr_1  (instruction_in_pipeline_2[25:21]),
   .raddr_2  (instruction_in_pipeline_2[20:16]),
   .waddr    (regfile_waddr     ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_data_1_in_pipeline    ),
   .rdata_2  (regfile_data_2_in_pipeline    )
);

reg_arstn_en	#(.DATA_W(32))
read_data_1_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (regfile_data_1_in_pipeline),
    .en    (enable),
    .dout  (regfile_data_1)
);


reg_arstn_en	#(.DATA_W(32))
read_data_2_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (regfile_data_2_in_pipeline),
    .en    (enable),
    .dout  (regfile_data_2)
);

reg_arstn_en	#(.DATA_W(32))
immediate_extend_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (immediate_extended_in_pipeline),
    .en    (enable),
    .dout  (immediate_extended)
);


reg_arstn_en	#(.DATA_W(1))
branch_in_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (branch_in_pipeline),
    .en    (enable),
    .dout  (branch)
);

reg_arstn_en	#(.DATA_W(1))
mem_read_in_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (mem_read_in_pipeline),
    .en    (enable),
    .dout  (mem_read)
);

reg_arstn_en	#(.DATA_W(1))
mem_2_reg_in_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (mem_2_reg_in_pipeline),
    .en    (enable),
    .dout  (mem_2_reg_in_pipeline_2)
);

reg_arstn_en	#(.DATA_W(1))
mem_write_in_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (mem_write_in_pipeline),
    .en    (enable),
    .dout  (mem_write_in_pipeline_2)
);

reg_arstn_en	#(.DATA_W(1))
alu_src_in_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (alu_src_in_pipeline),
    .en    (enable),
    .dout  (alu_src)
);



reg_arstn_en	#(.DATA_W(1))
jump_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (jump_in_pipeline),
    .en    (enable),
    .dout  (jump)
);

reg_arstn_en	#(.DATA_W(1))
reg_dst_1 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (reg_dst_in_pipeline),
    .en    (enable),
    .dout  (reg_dst_in_pipeline_2)
);

reg_arstn_en	#(.DATA_W(1))
reg_write_1 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (reg_write_in_pipeline),
    .en    (enable),
    .dout  (reg_write_in_pipeline_2)
);

reg_arstn_en	#(.DATA_W(4))
alu_control_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (alu_control_in_pipeline),
    .en    (enable),
    .dout  (alu_control)
);

reg_arstn_en	#(.DATA_W(32))
updated_pc_pc_plus_4_2 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (updated_pc_in_pipeline_2),
    .en    (enable),
    .dout  (updated_pc)
);

reg_arstn_en	#(.DATA_W(32))
instruction_pipe_2 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (instruction_in_pipeline_2),
    .en    (enable),
    .dout  (instruction_in_pipeline_3)
);






mux_2 #(
   .DATA_W(32)
) bypassing_A_mux (
   .input_a (regfile_wdata            ),
   .input_b (alu_out_in_pipeline_2    ),
   .select_a(memForward               ),
   .mux_out (alu_bypassing            )
);


mux_2 #(
   .DATA_W(32)
) operand_A_mux (
   .input_a (alu_bypassing              ),
   .input_b (regfile_data_1             ),
   .select_a(forwardA                   ),
   .mux_out (alu_operand_1              )
);



mux_2 #(
   .DATA_W(32)
) alu_operand_mux (
   .input_a (immediate_extended),
   .input_b (regfile_data_2    ),
   .select_a(alu_src           ),
   .mux_out (alu_operand_B     )
);




mux_2 #(
   .DATA_W(32)
) operand_B_mux (
   .input_a (alu_bypassing           ),
   .input_b (alu_operand_B           ),
   .select_a(forwardB                ),
   .mux_out (alu_operand_2           )
);


alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (alu_operand_1),
   .alu_in_1 (alu_operand_2 ),
   .alu_ctrl (alu_control   ),
   .alu_out  (alu_out_in_pipeline       ),
   .shft_amnt(instruction_in_pipeline_3[10:6]),
   .zero_flag(zero_flag     ),
   .overflow (              )
);

branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (updated_pc        ),
   .instruction  (instruction_in_pipeline_3       ),
   .branch_offset(immediate_extended),
   .branch_pc    (branch_pc         ),
   .jump_pc      (jump_pc         )
);

reg_arstn_en	#(.DATA_W(32))
instruction_pipe_3 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (instruction_in_pipeline_3),
    .en    (enable),
    .dout  (instruction_in_pipeline_4)
);





reg_arstn_en	#(.DATA_W(32))
alu_op_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (alu_out_in_pipeline),
    .en    (enable),
    .dout  (alu_out_in_pipeline_2)
);


reg_arstn_en	#(.DATA_W(1))
mem_2_reg_in_reg_2 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (mem_2_reg_in_pipeline_2),
    .en    (enable),
    .dout  (mem_2_reg_in_pipeline_3)
);

reg_arstn_en	#(.DATA_W(1))
mem_write_in_reg_2 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (mem_write_in_pipeline_2),
    .en    (enable),
    .dout  (mem_write)
);

reg_arstn_en	#(.DATA_W(1))
reg_dst_2 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (reg_dst_in_pipeline_2),
    .en    (enable),
    .dout  (reg_dst_in_pipeline_3)
);

reg_arstn_en	#(.DATA_W(1))
reg_write_2 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (reg_write_in_pipeline_2),
    .en    (enable),
    .dout  (reg_write_in_pipeline_3)
);


sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk           ),
   .addr     (alu_out_in_pipeline_2       ), //this is alu_out_in_pipeline_2 because we are still on that clock
   .wen      (mem_write     ),
   .ren      (mem_read      ),
   .wdata    (regfile_data_2),
   .rdata    (dram_data_in_pipeline     ),   
   .addr_ext (addr_ext_2    ),
   .wen_ext  (wen_ext_2     ),
   .ren_ext  (ren_ext_2     ),
   .wdata_ext(wdata_ext_2   ),
   .rdata_ext(rdata_ext_2   )
);


reg_arstn_en	#(.DATA_W(32))
instruction_pipe_4 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (instruction_in_pipeline_4),
    .en    (enable),
    .dout  (instruction)
);


reg_arstn_en	#(.DATA_W(32))
dram_data_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (dram_data_in_pipeline),
    .en    (enable),
    .dout  (dram_data)
);

reg_arstn_en	#(.DATA_W(32))
alu_out_reg_2 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (alu_out_in_pipeline_2),
    .en    (enable),
    .dout  (alu_out)
);

reg_arstn_en	#(.DATA_W(1))
mem_2_reg_in_reg_3 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (mem_2_reg_in_pipeline_3),
    .en    (enable),
    .dout  (mem_2_reg)
);

reg_arstn_en	#(.DATA_W(1))
reg_dst_3 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (reg_dst_in_pipeline_3),
    .en    (enable),
    .dout  (reg_dst)// will be used in the first stage
);

reg_arstn_en	#(.DATA_W(1))
reg_write_3 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (reg_write_in_pipeline_3),
    .en    (enable),
    .dout  (reg_write)
);

mux_2 #( //WRITEBACK STAGE
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (dram_data    ),
   .input_b  (alu_out      ),
   .select_a (mem_2_reg     ),
   .mux_out  (regfile_wdata)
);

mux_2 #( 
   .DATA_W(5)
) destination_data_mux (
   .input_a  (instruction_in_pipeline_4[15:11]     ),
   .input_b  (instruction_in_pipeline_4[20:16]     ),
   .select_a (reg_dst_in_pipeline_3                ),//is instruction in EX/MEM R format?
   .mux_out  (destination_addr                     )
);


forwarding_unit forwarding_unit(
		.ExMemRegwrite   (  reg_write_in_pipeline_3        ),
		.MemWbregwrite   (                reg_write        ),
		.ExMemRegisterRd (         destination_addr        ),
		.IdExRegisterRs  (instruction_in_pipeline_3[25:21] ),
		.IdExRegisterRt  (instruction_in_pipeline_3[20:16] ),
		.MemWbRegisterRd (              instruction[20:16] ),
		.reg_dst         (    reg_dst_in_pipeline_2        ),
		.is_load_1       (  mem_2_reg_in_pipeline_2        ),
		.is_load_2       (                mem_2_reg        ),
		.memForward      (               memForward        ),
		.forwardA        (                 forwardA        ),
		.forwardB        (                 forwardB        )
   );
data_hazard_detection_unit data_hazard_detection_unit(
		.IdExMemread     (  mem_2_reg_in_pipeline_2        ),
		.IdExRegisterRt  (instruction_in_pipeline_3[20:16] ),
		.IfIdRegisterRt  (instruction_in_pipeline_2[20:16] ),
		.IfIdRegisterRs  (instruction_in_pipeline_2[25:21] ),
		.stall           (            	 data_stall        )
   );
endmodule
module forwarding_unit(
		input  wire 		 ExMemRegwrite,
		input  wire 		 MemWbregwrite,
		input  wire [4:0]    ExMemRegisterRd,
		input  wire [4:0]    IdExRegisterRs,
		input  wire [4:0]    IdExRegisterRt,
		input  wire [4:0]    MemWbRegisterRd,
		input  wire          reg_dst,
		input  wire          is_load_1,
		input  wire          is_load_2,
		output wire          memForward,
		output wire          forwardA,
		output wire          forwardB
   );
	wire aluForwardA,aluForwardB,memForwardB,memForwardA;
	assign aluForwardA = ExMemRegwrite & (ExMemRegisterRd == IdExRegisterRs);
	assign aluForwardB = ExMemRegwrite & (ExMemRegisterRd == IdExRegisterRt);
	assign memForwardA = MemWbregwrite & (MemWbRegisterRd == IdExRegisterRs) & ~(aluForwardA) & is_load_2;
	assign memForwardB = MemWbregwrite & (MemWbRegisterRd == IdExRegisterRt) & ~(aluForwardB) & is_load_2;
	assign memForward  = memForwardA   | memForwardB;
	assign forwardA    = (memForwardA  |  aluForwardA) & ~(is_load_1);
	assign forwardB    = (memForwardB  |  aluForwardB) &   reg_dst ;

endmodule
module data_hazard_detection_unit(
		input  wire 		 IdExMemread,
		input  wire [4:0]    IdExRegisterRt,
		input  wire [4:0]    IfIdRegisterRt,
		input  wire [4:0]    IfIdRegisterRs,
		output wire          stall 
   );
	wire stall1;
	wire stall2;
	wire stall3;
	assign stall1 = ( IdExRegisterRt == IfIdRegisterRt );
	assign stall2 = ( IdExRegisterRt == IfIdRegisterRs );
	assign stall3 = ( stall1         |  stall2         );
	assign stall  = ( stall3         &  IdExMemread    ); 
endmodule

