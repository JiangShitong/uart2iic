
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/01/2024 08:57:37 AM
// Design Name: 
// Module Name: i2c_controller
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




`timescale 1ns / 1ps
module i2c_controller(
	input wire clk, 
	input wire rst_n,
	input wire [6:0] device_addr,
	input wire rw,	
	input wire [7:0] reg_addr,	
	input wire [15:0] data_in,
	input wire enable,

	output reg [15:0] data_out,
	output wire ready,

	inout i2c_sda,
	inout wire i2c_scl  
	);

	localparam IDLE = 0;
	localparam START = 1;
	localparam DEVICE = 2;
	localparam DEVICE_ACK = 3;
	localparam ADDRESS = 4;	
	localparam ADDRESS_ACK = 5;
	localparam WRITE_DATA1 = 6;
	localparam WRITE_DATA1_ACK = 7;	
	localparam WRITE_DATA2 = 8;
	localparam WRITE_DATA2_ACK = 9;	
	localparam READ_DATA1 = 10;
	localparam READ_DATA1_ACK = 11;
	localparam READ_DATA2 = 12;
	localparam READ_DATA2_ACK = 13;		
	localparam STOP = 14;
	
	localparam DIVIDE_BY = 250; //max 400kHz, min 1kHz

	reg [7:0] state;
	reg [7:0] saved_device;
	reg [7:0] saved_address;
	reg [15:0] saved_data;
	reg [7:0] counter;
	reg [7:0] counter_for_divide_clk;
	reg write_enable;
	reg sda_out;
	reg i2c_scl_enable = 0;
	reg i2c_clk = 1;
	reg reg_enable;

	assign ready = ((rst_n == 1) && (state == IDLE)) ? 1 : 0;
	assign i2c_scl = (i2c_scl_enable == 0 ) ? 1 : i2c_clk;
	assign i2c_sda = (write_enable == 1) ? sda_out : 'bz;

//divided clock	
	always @(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    i2c_clk <= 1'd0;
			counter_for_divide_clk <= 8'd0;
	    end
		else if (counter_for_divide_clk == (DIVIDE_BY/2) - 1) begin
			i2c_clk <= ~i2c_clk;
			counter_for_divide_clk <= 0;
		end
		else counter_for_divide_clk <= counter_for_divide_clk + 1;
	end 
	
	always @(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    reg_enable <= 1'd0;
	    end
		else if (enable) begin
			reg_enable <= 1'd1;
		end
		else if (state == START) begin
		    reg_enable <= 1'd0;
	    end
		else reg_enable <= reg_enable;
	end 	

//SCL enable	
	always @(negedge i2c_clk or negedge rst_n) begin
		if(!rst_n) begin
			i2c_scl_enable <= 0;
		end else begin
			if ((state == IDLE) || (state == START) || (state == STOP)) begin
				i2c_scl_enable <= 0;
			end else begin
				i2c_scl_enable <= 1;
			end
		end	
	end

	always @(posedge i2c_clk or negedge rst_n) begin
		if(!rst_n) begin
			state <= IDLE;
			saved_device <= 'd0;
			saved_data <= 'd0;
			saved_address <= 'd0;
			counter <= 'd0;
			data_out <= 'd0;
		end		
		else begin
			case(state)			
				IDLE: begin
					if (reg_enable) begin
						state <= START;
						saved_device <= {device_addr, rw};
						saved_data <= data_in;
						saved_address <= reg_addr;
					end
					else state <= IDLE;
				end

				START: begin
					counter <= 7;
					state <= DEVICE;
				end

				DEVICE: begin
					if (counter == 0) begin 
						state <= DEVICE_ACK;
					end else counter <= counter - 1;
				end	

				DEVICE_ACK: begin
					if (i2c_sda == 0) begin					
					    if(saved_device[0] == 0) begin						
						state <= ADDRESS;
						counter <= 7;
						end
						else begin
						state <= READ_DATA1;
						counter <= 15;
						end
					end 
					else state <= STOP;
				end				

				ADDRESS: begin
					if (counter == 0) begin 
						state <= ADDRESS_ACK;
					end else counter <= counter - 1;
				end					

				ADDRESS_ACK: begin
					if (i2c_sda == 0) begin
						counter <= 15;
						state <= WRITE_DATA1;
					end else state <= STOP;
				end

				WRITE_DATA1: begin
					if(counter == 8) begin
						state <= WRITE_DATA1_ACK;
					end else counter <= counter - 1;
				end
				
				WRITE_DATA1_ACK: begin
					if (i2c_sda == 0) begin
                    state <= WRITE_DATA2;
					end else state <= STOP;
				end		
				
				WRITE_DATA2: begin
					if(counter == 0) begin
						state <= WRITE_DATA2_ACK;
					end else counter <= counter - 1;
				end
				
				WRITE_DATA2_ACK: begin
                    state <= STOP;
				end					

				READ_DATA1: begin
					data_out[counter] <= i2c_sda;
					if (counter == 8) state <= READ_DATA1_ACK;
					else counter <= counter - 1;
				end
				
				READ_DATA1_ACK: begin
                    state <= READ_DATA2;
				end		

				READ_DATA2: begin
					data_out[counter] <= i2c_sda;
					if (counter == 0) state <= READ_DATA2_ACK;
					else counter <= counter - 1;
				end				
				
				READ_DATA2_ACK: begin
					state <= STOP;
				end

				STOP: begin
					state <= IDLE;
				end
			endcase
		end
	end
	
	always @(negedge i2c_clk or negedge rst_n) begin
		if(!rst_n) begin
			write_enable <= 1;
			sda_out <= 1;
		end else begin
			case(state)
				
				START: begin
					write_enable <= 1;
					sda_out <= 0;
				end
				
				DEVICE: begin
					sda_out <= saved_device[counter];			
				end
				
				DEVICE_ACK: begin
					write_enable <= 0;
				end	

				ADDRESS: begin
				    write_enable <= 1;
					sda_out <= saved_address[counter];
				end				
				
				ADDRESS_ACK: begin
					write_enable <= 0;
				end
				
				WRITE_DATA1: begin 
					write_enable <= 1;
					sda_out <= saved_data[counter];
				end
				
				READ_DATA1: begin
					write_enable <= 0;
				end			
				
				READ_DATA1_ACK: begin
					write_enable <= 1;
					sda_out <= 0;
				end		

				READ_DATA2: begin
					write_enable <= 0;
				end			
				
				READ_DATA2_ACK: begin
					write_enable <= 1;
					sda_out <= 0;
				end					
				
				WRITE_DATA1_ACK: begin
					write_enable <= 0;
				end					
				
				WRITE_DATA2: begin 
					write_enable <= 1;
					sda_out <= saved_data[counter];
				end
				
				WRITE_DATA2_ACK: begin
					write_enable <= 0;
				end									
				
				STOP: begin
					write_enable <= 1;
					sda_out <= 1;
				end
			endcase
		end
	end

endmodule
