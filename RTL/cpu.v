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
                  instruction, instruction_in_pipeline, updated_pc_in_pipeline, regfile_data_1_in_pipeline, regfile_data_2_in_pipeline,
                  branch_pc_in_pipeline, jump_pc_in_pipeline;
wire [       1:0] alu_op;
wire [       3:0] alu_control, alu_control_in_pipeline;
wire              reg_dst,branch,mem_read,mem_2_reg, reg_write,
                  mem_write,alu_src,  jump, branch_in_pipeline, mem_read_in_pipeline, mem_2_reg_in_pipeline, mem_write_in_pipeline,alu_src_in_pipeline,   jump_in_pipeline,
                  mem_write_in_pipeline_2, mem_2_reg_in_pipeline_2, mem_2_reg_in_pipeline_3;
wire [       4:0] regfile_waddr;
wire [      31:0] regfile_wdata, dram_data, dram_data_in_pipeline,alu_out, alu_out_in_pipeline, alu_out_in_pipeline_2,
                  regfile_data_1,regfile_data_2,
                  alu_operand_2;

wire signed [31:0] immediate_extended_in_pipeline, immediate_extended;

assign immediate_extended_in_pipeline = $signed(instruction[15:0]);


pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc ),
   .jump_pc   (jump_pc   ),
   .zero_flag (zero_flag ),
   .branch    (branch    ),
   .jump      (jump      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc_in_pipeline)
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
   .rdata    (instruction_in_pipeline   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);



reg_arstn_en	#(.DATA_W(32))
instruction_pipe (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (instruction_in_pipeline),
    .en    (enable),
    .dout  (instruction)
);

reg_arstn_en	#(.DATA_W(32))
updated_pc_pc_plus_4 (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (updated_pc_in_pipeline),
    .en    (enable),
    .dout  (updated_pc)
);





control_unit control_unit(
   .opcode   (instruction[31:26]),
   .reg_dst  (reg_dst           ),
   .branch   (branch_in_pipeline            ),
   .mem_read (mem_read_in_pipeline          ),
   .mem_2_reg(mem_2_reg_in_pipeline         ),
   .alu_op   (alu_op            ),
   .mem_write(mem_write_in_pipeline         ),
   .alu_src  (alu_src_in_pipeline           ),
   .reg_write(reg_write        ),
   .jump     (jump_in_pipeline              )
);


mux_2 #(
   .DATA_W(5)
) regfile_dest_mux (
   .input_a (instruction[15:11]),
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
   .raddr_1  (instruction[25:21]),
   .raddr_2  (instruction[20:16]),
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

reg_arstn_en	#(.DATA_W(4))
alu_control_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (alu_control_in_pipeline),
    .en    (enable),
    .dout  (alu_control)
);




alu_control alu_ctrl(
   .function_field (instruction[5:0]),
   .alu_op         (alu_op          ),
   .alu_control    (alu_control_in_pipeline     )
);





mux_2 #(
   .DATA_W(32)
) alu_operand_mux (
   .input_a (immediate_extended),
   .input_b (regfile_data_2    ),
   .select_a(alu_src           ),
   .mux_out (alu_operand_2     )
);


alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (regfile_data_1),
   .alu_in_1 (alu_operand_2 ),
   .alu_ctrl (alu_control   ),
   .alu_out  (alu_out_in_pipeline       ),
   .shft_amnt(instruction[10:6]),
   .zero_flag(zero_flag_in_pipeline     ),
   .overflow (              )
);

branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (updated_pc        ),
   .instruction  (instruction       ),
   .branch_offset(immediate_extended),
   .branch_pc    (branch_pc_in_pipeline         ),
   .jump_pc      (jump_pc_in_pipeline         )
);

reg_arstn_en	#(.DATA_W(32))
branch_pc_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (branch_pc_in_pipeline),
    .en    (enable),
    .dout  (branch_pc)
);


reg_arstn_en	#(.DATA_W(32))
jump_pc_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (jump_pc_in_pipeline),
    .en    (enable),
    .dout  (jump_pc)
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
zero_reg (
    .clk (clk ),
    .arst_n(arst_n  ),
    .din   (zero_flag_in_pipeline),
    .en    (enable),
    .dout  (zero_flag)
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


sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk           ),
   .addr     (alu_out       ), //should this not be alu_out_in_pipeline instead of alu_out? 
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



mux_2 #(
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (dram_data    ),
   .input_b  (alu_out      ),
   .select_a (mem_2_reg     ),
   .mux_out  (regfile_wdata)
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



endmodule


