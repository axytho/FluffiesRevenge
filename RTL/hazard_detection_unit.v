module hazard_detection_unit(
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