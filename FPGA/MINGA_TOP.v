`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 2020/12/23 14:26:31
// Design Name: MINGA
// Module Name: MINGA_TOP
// Project Name: MINGA
// Target Devices: xc7vx690tffg1761-2 (active)
// Tool Versions: vivado 2017.04
// Revision:
// Revision 0.01 - File Created
// 
//////////////////////////////////////////////////////////////////////////////////


module MINGA_TOP(
	input 			sys_clk	,		//system clock
	input 			rst_n 	,		//reset signal,active low
	input [31:0] 	e 		,		//element to insert
	input 			e_valid			//element valid signal	
    );

	parameter LENGTH = 64 * 1024;
	//parameter LENGTH = 32 ;


	wire[31:0] hash							;	//the hash of e
	wire 	   hash_valid 					;	//hash valid

	wire[31:0] random_num 					;	//the random number
	wire[31:0] random_num_2  				;
	reg [31:0] random_num_reg 				;
	reg [31:0] random_num_reg_0 			;

	//generate a random number using the current time
	reg [63:0] timer 						;	//timer register

	//the counter ram signal
	reg 	   counter_ram_ena				;   //ena of counter ram port a 
	reg 	   counter_ram_wea				;   //wea of counter ram port a
	reg [15:0] counter_ram_addra			;  	//addra of counter ram port a
	reg [31:0] counter_ram_dina				;   //dina of counter ram port a
	wire[31:0] counter_ram_douta			;  	//douta of counter ram port a
	reg 	   counter_ram_enb				;   //ena of counter ram port a 
	reg 	   counter_ram_web				;   //wea of counter ram port a
	reg [15:0] counter_ram_addrb			;  	//addra of counter ram port a
	reg [31:0] counter_ram_dinb				;   //dina of counter ram port a
	wire[31:0] counter_ram_doutb			;  	//douta of counter ram port a

	//the register to cache the counter_ram_douta
	reg [31:0] counter_ram_douta_reg		;
	reg [31:0] counter_ram_douta_reg_0		;
	reg [31:0] counter_ram_douta_reg_1		;

	//the ID ram signal
	reg 	   ID_ram_ena					;   //ena of ID ram port a
	reg 	   ID_ram_wea					;   //wea
	reg [15:0] ID_ram_addra					;  	//addra
	reg [31:0] ID_ram_dina					;   //dina
	wire[31:0] ID_ram_douta					;  	//douta

	//the cache register
	reg [31:0] e_reg 						;	//cache the e value
	reg [31:0] e_reg_0 						;
	reg [31:0] e_reg_1 						;
	reg [31:0] e_reg_2 						;
	reg [31:0] e_reg_3 						; 
	reg [31:0] e_reg_4 						; 
	reg [31:0] e_reg_5 						; 
	reg [31:0] e_reg_6 						; 
	reg [15:0] counter_ram_addra_0 			;
	reg [15:0] counter_ram_addra_1 			;
	reg [15:0] counter_ram_addra_2 			;
	reg [15:0] counter_ram_addra_3 			;
	reg [15:0] counter_ram_addra_4 			;
	reg [15:0] counter_ram_addra_5 			;
	reg [15:0] counter_ram_addra_6 			;
	reg 	   valid_0 						;	
	reg 	   valid_1 						;
	reg 	   valid_2 						;
	reg 	   valid_3 						;
	reg 	   valid_4 						;
	reg 	   valid_5 						;
	reg 	   valid_6 						;

	reg [63:0] multi_result_1				;
	reg [63:0] multi_result_2				;
	reg [63:0] multi_result_1_0				;
	reg [63:0] multi_result_2_0				;
	reg [63:0] multi_result_3				;
	reg [63:0] multi_result_4				;

	integer i ;

	//record the current time in timer register
	//cache the e value in e_reg
	always @ (posedge sys_clk or negedge rst_n) begin
	    if (~rst_n) begin
	        timer 					<= 64'b0;
	        counter_ram_douta_reg	<= 32'b0;
	        counter_ram_douta_reg_0 <= 32'b0;
	        counter_ram_douta_reg_1 <= 32'b0;
	        random_num_reg 			<= 32'b0;
	        random_num_reg_0 		<= 32'b0;
	    end
	    else begin
	    	timer <= timer + 64'b1;
	    	counter_ram_douta_reg <= counter_ram_douta;
	    	counter_ram_douta_reg_0 <= counter_ram_douta_reg;
	    	counter_ram_douta_reg_1 <= counter_ram_douta_reg_0;
	    	random_num_reg <= random_num;
	    	random_num_reg_0 <= random_num_reg;
	    end
	end

	always @ (posedge sys_clk or negedge rst_n) begin
	    if (~rst_n) begin
	        counter_ram_ena	 		<= 1'b0		; 
			counter_ram_wea	 		<= 1'b0		; 
			counter_ram_addra		<= 16'b0	; 
			counter_ram_dina		<= 32'b0	; 
	    end
	    else begin
	    	if (hash_valid == 1'b1) begin
	    		$display("the index is %d ",hash % LENGTH);
	    		//counter_array[hash % LENGTH] <= counter_array[hash % LENGTH] + 64'b1;
	    		counter_ram_ena	 		<= 1'b1				; 
				counter_ram_wea	 		<= 1'b0				; 
				counter_ram_addra		<= hash % LENGTH	; 
				counter_ram_dina		<= 32'b0			;
	    	end
	    	else begin
	    		counter_ram_ena	 		<= 1'b0				; 
				counter_ram_wea	 		<= 1'b0				; 
				counter_ram_addra		<= 16'b0			; 
				counter_ram_dina		<= 32'b0			;
	    	end
	    end
	end

	//cache the address, e and valid signal 
	always @(posedge sys_clk or negedge rst_n)begin
		if (~rst_n) begin
			e_reg 				<= 32'b0				;
	        e_reg_0 			<= 32'b0				;
			e_reg_1 			<= 32'b0				;
			e_reg_2 			<= 32'b0				;
			e_reg_3 			<= 32'b0				;
			e_reg_4 			<= 32'b0				;
			e_reg_5 			<= 32'b0				;
			e_reg_6 			<= 32'b0				;
			counter_ram_addra_0	<= 16'b0 				;
			counter_ram_addra_1	<= 16'b0 				;
			counter_ram_addra_2	<= 16'b0 				;
			counter_ram_addra_3	<= 16'b0 				;
			counter_ram_addra_4	<= 16'b0 				;
			counter_ram_addra_5	<= 16'b0 				;
			counter_ram_addra_6	<= 16'b0 				;
			valid_0				<= 1'b0 				;	
			valid_1				<= 1'b0 				;
			valid_2				<= 1'b0 				;
			valid_3				<= 1'b0 				;
			valid_4				<= 1'b0 				;
			valid_5				<= 1'b0 				;
			valid_6				<= 1'b0 				;
	    end	
	    else begin	
	    	e_reg 				<= e 					;
	        e_reg_0 			<= e_reg				;
			e_reg_1 			<= e_reg_0				;
			e_reg_2 			<= e_reg_1				;
			e_reg_3 			<= e_reg_2				;
			e_reg_4 			<= e_reg_3				;
			e_reg_5 			<= e_reg_4				;
			e_reg_6 			<= e_reg_5				;
			counter_ram_addra_0	<= hash % LENGTH 		;
			counter_ram_addra_1	<= counter_ram_addra_0 	;
			counter_ram_addra_2	<= counter_ram_addra_1	;
			counter_ram_addra_3	<= counter_ram_addra_2	;
			counter_ram_addra_4	<= counter_ram_addra_3	;
			counter_ram_addra_5	<= counter_ram_addra_4	;
			counter_ram_addra_6	<= counter_ram_addra_5	;
			valid_0				<= hash_valid 			;	
			valid_1				<= valid_0 				;
			valid_2				<= valid_1 				;
			valid_3				<= valid_2 				;
			valid_4				<= valid_3 				;
			valid_5				<= valid_4 				;
			valid_6				<= valid_5 				;
	    end
	end

	always @(posedge sys_clk or negedge rst_n) begin
		if(~rst_n) begin
			 multi_result_1 	<= 64'b0;
			 multi_result_2 	<= 64'b0;
			 multi_result_1_0 	<= 64'b0;
			 multi_result_2_0 	<= 64'b0;
			 multi_result_3 	<= 64'b0;
			 multi_result_4 	<= 64'b0;
		end 
		else begin
			if (valid_4 == 1'b1) begin
				multi_result_1 <= random_num_reg[31:16] * counter_ram_douta_reg[31:16];
				multi_result_2 <= random_num_reg[31:16] * counter_ram_douta_reg[15:0];
			end
			if (valid_5 == 1'b1) begin
				multi_result_3 <= random_num_reg_0[15:0] * counter_ram_douta_reg_0[31:16];
				multi_result_4 <= random_num_reg_0[15:0] * counter_ram_douta_reg_0[15:0];
			end
			multi_result_1_0 <= multi_result_1;
			multi_result_2_0 <= multi_result_2;
		end
	end

	always @(posedge sys_clk or negedge rst_n)begin
		if (~rst_n) begin
			counter_ram_enb	 		<= 1'b0		;
			counter_ram_web	 		<= 1'b0		;
			counter_ram_addrb		<= 16'b0	;
			counter_ram_dinb		<= 64'b0	;

			ID_ram_ena	 			<= 1'b0		; 
			ID_ram_wea	 			<= 1'b0		; 
			ID_ram_addra			<= 16'b0	; 
			ID_ram_dina				<= 64'b0	;
		end
		else begin
			if (valid_6 == 1'b1)  begin
				counter_ram_enb	 		<= 1'b1							;
				counter_ram_web	 		<= 1'b1							;
				counter_ram_addrb		<= counter_ram_addra_5			;
				counter_ram_dinb		<= counter_ram_douta_reg_1 + 64'b1	;
				if ({multi_result_1_0[63:32],32'b0} + {multi_result_2_0[63:16],16'b0} +  {multi_result_3[63:16],16'b0} + {multi_result_4} < 2**32) begin
					ID_ram_ena	 			<= 1'b1						; 
					ID_ram_wea	 			<= 1'b1						; 
					ID_ram_addra			<= counter_ram_addra_6		; 
					ID_ram_dina				<= e_reg_6 					;
				end
				else begin
					ID_ram_ena	 			<= 1'b0						; 
					ID_ram_wea	 			<= 1'b0						; 
					ID_ram_addra			<= counter_ram_addra_6					; 
					ID_ram_dina				<= e_reg_6 					;
				end
			end
			else begin
				counter_ram_enb	 		<= 1'b0		;
				counter_ram_web	 		<= 1'b0		;
				counter_ram_addrb		<= 16'b0	;
				counter_ram_dinb		<= 64'b0	;

				ID_ram_ena	 			<= 1'b0		; 
				ID_ram_wea	 			<= 1'b0		; 
				ID_ram_addra			<= counter_ram_addra_6	; 
				ID_ram_dina				<= e_reg_6	;
			end			
		end
	end

	//generate the random number
	crc32_64bit_gen random_num_gen(
    .clk		(sys_clk			), 	//system reset
	.reset_n	(rst_n 				),	//reset signal, active low
	.data		(timer 				),	//insert element
	.datavalid	(valid_2			),	//element valid
	.checksum	(random_num			),
	.crcvalid	(					)
	);

	crc32_64bit_gen random_num_gen2(
    .clk		(sys_clk			), 	//system reset
	.reset_n	(rst_n 				),	//reset signal, active low
	.data		(timer*3+64'b1 		),	//insert element
	.datavalid	(valid_2			),	//element valid
	.checksum	(random_num_2		),
	.crcvalid	(					)
	);



	//generate the hash
	crc32_64bit_gen hash_gen(
    .clk		(sys_clk			), 	//system reset
	.reset_n	(rst_n 				),	//reset signal, active low
	.data		(e 					),	//insert element
	.datavalid	(e_valid			),	//element valid
	.checksum	(hash				),
	.crcvalid	(hash_valid			)
	);

	//the ram to save the counter array
	ram_32b_64K counter_ram (
	  .clka	(sys_clk			),    	// input wire clka
	  .ena	(counter_ram_ena	),      // input wire ena
	  .wea	(counter_ram_wea	),      // input wire [0 : 0] wea
	  .addra(counter_ram_addra	),  	// input wire [15 : 0] addra
	  .dina	(counter_ram_dina	),    	// input wire [63 : 0] dina
	  .douta(counter_ram_douta	),  	// output wire [63 : 0] douta
	  .clkb	(sys_clk			),    	// input wire clkb
	  .enb	(counter_ram_enb	),      // input wire enb
	  .web	(counter_ram_web	),      // input wire [0 : 0] web
	  .addrb(counter_ram_addrb	),  	// input wire [15 : 0] addrb
	  .dinb	(counter_ram_dinb	),    	// input wire [63 : 0] dinb
	  .doutb(counter_ram_doutb	)  		// output wire [63 : 0] doutb
	);

	//the ram to save the ID array
	ram_32b_64K ID_ram (
	  .clka(sys_clk),    // input wire clka
	  .ena(ID_ram_ena),      // input wire ena
	  .wea(ID_ram_wea),      // input wire [0 : 0] wea
	  .addra(ID_ram_addra),  // input wire [15 : 0] addra
	  .dina(ID_ram_dina),    // input wire [31 : 0] dina
	  .douta(ID_ram_douta),  // output wire [31 : 0] douta
	  .clkb(sys_clk),    // input wire clkb
	  .enb(1'b0),      // input wire enb
	  .web(1'b0),      // input wire [0 : 0] web
	  .addrb(16'b0),  // input wire [15 : 0] addrb
	  .dinb(32'b0),    // input wire [31 : 0] dinb
	  .doutb()  // output wire [31 : 0] doutb
	);


endmodule
