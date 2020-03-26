module forwarding_unit(
		input  wire 		 ExMemRegwrite,
		input  wire 		 MemWbregwrite,
		input  wire [4:0]    ExMemRegisterRd,
		input  wire [4:0]    IdExRegisterRs,
		input  wire [4:0]    IdExRegisterRt,
		input  wire [4:0]    MemWbRegisterRd,
		output wire          memForward,
		output wire          forwardA,
		output wire          forwardB
   );
	wire aluForwardA,aluForwardB,memForwardB,memForwardA;
	assign memForwardA = MemWbregwrite & (MemWbRegisterRd == IdExRegisterRs);
	assign memForwardB = MemWbregwrite & (MemWbRegisterRd == IdExRegisterRt);
	assign memForward  = memForwardA   | memForwardB;
	assign aluForwardA = ExMemRegwrite & (ExMemRegisterRd == IdExRegisterRs);
	assign aluForwardB = ExMemRegwrite & (ExMemRegisterRd == IdExRegisterRt);
	assign forwardA    = memForwardA   |  aluForwardA;
	assign forwardB    = memForwardB   |  aluForwardB;

endmodule