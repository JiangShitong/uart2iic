//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2024 04:59:05 PM
// Design Name: 
// Module Name: uart_tb
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

module uart_tb;

  reg            clk;
  reg            rst_n;
  reg            RXD;
  wire           TXD;

parameter  UART_BPS     = 115200;                    //´®¿Ú²¨ÌØÂÊ 
parameter  I2C_frequency = 400000;                   //max 400kHz, min 1kHz
localparam UART_BPS_ns  = 1000000000/UART_BPS;
localparam UART_tranmit_time = UART_BPS_ns*10;
localparam I2C_tranmit_time = 40*1000000000/I2C_frequency;
localparam DEVICE_ADDRESS = 7'b1000000;
localparam WRITE = 1'b0;
localparam READ = 1'b1;
localparam CONFIGURATION_REG = 8'b00000000;	

wire i2c_scl,i2c_sda;
reg [10:0] i;

  initial begin
    clk = 0;
    rst_n = 0;
    RXD = 1;
    #100;
    rst_n = 1;
    #UART_BPS_ns;    
    #1000;
    send_uart({DEVICE_ADDRESS,WRITE});//b1000000
	send_uart(CONFIGURATION_REG);
	send_uart(8'hdf);
	send_uart(8'hac);
	#UART_tranmit_time;
	#I2C_tranmit_time;	
	send_uart({DEVICE_ADDRESS,WRITE});//b1000000
	send_uart(CONFIGURATION_REG);
	send_uart(8'hba);
	send_uart(8'h3c);
	#UART_tranmit_time;
	#I2C_tranmit_time;	
    send_uart({DEVICE_ADDRESS,READ});//b1000000
	send_uart(CONFIGURATION_REG);
	send_uart(8'haa);
	send_uart(8'hcc);
	#UART_tranmit_time;
	#I2C_tranmit_time;	
    $stop;
  end
  
  always #5 clk = ~clk;

 task send_uart;
    input [7:0] data;
    begin
	    RXD = 0;
        #UART_BPS_ns;
        for (i = 0; i < 8; i = i + 1) begin	          
          RXD <= data[i];
          #UART_BPS_ns; 
        end
	    RXD = 1;
        #(2*UART_BPS_ns);
    end
endtask

  uart uart_inst(
  
  .clk      (clk  ),
  .rst_n      (rst_n  ),
  .RXD      (RXD  ),
  .TXD      (TXD  ),
  .i2c_sda(i2c_sda), 
  .i2c_scl(i2c_scl)
);

	i2c_slave_controller slave (
    .sda(i2c_sda), 
    .scl(i2c_scl)
    );  
endmodule
