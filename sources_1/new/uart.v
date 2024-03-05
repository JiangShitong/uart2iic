`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2024 04:58:14 PM
// Design Name: 
// Module Name: uart
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


module uart(
  
  input   wire           clk,
  input   wire           rst_n,
  input   wire           RXD,
  output   wire           TXD,
  inout wire i2c_sda,
  inout wire i2c_scl
);

	wire [6:0]  device_addr;
	wire        rw;
	wire [7:0]  reg_addr;
	wire [15:0] i2c_data;
	wire        i2c_enable;
	wire [15:0] data_out;
	wire        ready;
    wire [7:0]  uart_rx_data;
    wire        rd_en;
    wire [7:0]  tx_data;
  
  uart_rx uart_rx_inst(
  
  .clk            (clk  ),
  .rst_n          (rst_n),
  .RXD            (RXD  ),
  .data           (uart_rx_data),
  .device_addr    (device_addr),  
  .rw             (rw),
  .reg_addr       (reg_addr),
  .i2c_data   (i2c_data),
  .i2c_enable     (i2c_enable)  
);
  
  i2c_controller i2c_controller(
  .clk(clk),
  .rst_n(rst_n),
  .device_addr(device_addr),
  .rw(rw),  
  .reg_addr(reg_addr),  
  .data_in(i2c_data),
  .enable(i2c_enable),
  .i2c_sda(i2c_sda),
  .i2c_scl(i2c_scl));
  
  /*
  uart_tx uart_tx_inst(
  
  .clk        (clk  ),
  .rst_n        (rst_n  ),
  .empty        (empty  ),
  .data        (tx_data),
  .rd_en        (rd_en  ),
  .TXD        (TXD  )
);*/

endmodule
