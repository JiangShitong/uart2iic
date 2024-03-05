`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2024 04:53:04 PM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
  
  input     wire           clk,
  input     wire           rst_n,
  input     wire           RXD,
  output    reg     [7:0]  data,
  output    reg     [6:0]  device_addr,  
  output    reg            rw,
  output    reg     [7:0]  reg_addr,
  output    reg     [15:0] i2c_data,
  output    reg            i2c_enable
);

  parameter  CLK_FREQ     = 100000000;                //系统时钟频率 
  parameter  UART_BPS     = 115200;                    //串口波特率 
  localparam BPS_CNT      = CLK_FREQ/UART_BPS;       //为得到指定波特率
  localparam UART_device  = 0;
  localparam UART_address = 1;
  localparam UART_data1   = 2;
  localparam UART_data2   = 3;

  reg     [1:0]   uart_state;
  reg     [14:0]  cnt;
  reg             flag;
  reg             rxd_r, rxd_rr;
  wire            rx_en;
  reg     [3:0]   num;
  reg     [7:0]   data_r;
  reg             done;
 
  always @ (posedge clk) rxd_r <= RXD;
  always @ (posedge clk) rxd_rr <= rxd_r;
  
  assign rx_en = (~rxd_r) & rxd_rr;
  
  always @ (posedge clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      cnt <= 15'd0;
    else if(flag)
      begin
        if(cnt == BPS_CNT - 1)
          cnt <= 15'd0;
        else
          cnt <= cnt + 1'b1;
      end
    else
      cnt <= 15'd0;
  end
  
  always @ (posedge clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      flag <= 1'b0;
    else if(rx_en)
      flag <= 1'b1;
    else if(num == 4'd10)
      flag <= 1'b0;
    else
      flag <= flag;
  end
  
  always @ (posedge clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      num <= 4'd0;
    else if(cnt == BPS_CNT - 1)
      num <= num + 1'b1;
    else if(num == 4'd10)
      num <= 4'd0;
    else
      num <= num;
  end
  
  always @ (posedge clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      begin
        data_r <= 8'd0;
        data <= 8'd0;
      end
    else if(cnt == BPS_CNT - 1)
      case(num)
        4'd0  :  ;
        4'd1  :  data_r[0] <= rxd_rr;
        4'd2  :  data_r[1] <= rxd_rr;
        4'd3  :  data_r[2] <= rxd_rr;
        4'd4  :  data_r[3] <= rxd_rr;
        4'd5  :  data_r[4] <= rxd_rr;
        4'd6  :  data_r[5] <= rxd_rr;
        4'd7  :  data_r[6] <= rxd_rr;
        4'd8  :  data_r[7] <= rxd_rr;
        4'd9  :  data <= data_r;
        default  :  data <= data;
      endcase
  end
  
//new
  always @ (posedge clk, negedge rst_n)
  begin
    if(rst_n == 1'b0)
      done <= 1'b0;
    else if((num == 4'd9)&&(cnt == 'd0))
      done <= 1'b1;
    else
      done <= 1'b0;
  end  
  

  always @ (posedge clk or negedge rst_n)
  begin
    if(rst_n == 1'b0) begin
      uart_state <= 2'd0;
	  i2c_enable <= 1'd0;
	end
    else if(done) begin
	  if(uart_state == 2'd3) begin
	    uart_state <= 2'd0;
		i2c_enable <= 1'd1;
	  end
	  else begin
	    uart_state <= uart_state + 2'b1;
		i2c_enable <= 1'd0;
	  end
    end
    else begin
      uart_state <= uart_state;
	  i2c_enable <= 1'd0;
	end
  end  
  
  always @ (posedge clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      device_addr <= 7'd0;
    else begin
	  case(uart_state)
		UART_device: begin
		if(done)
		device_addr <= data_r[7:1];
		end
		default: begin
		device_addr <= device_addr;
		end
	  endcase
    end
  end

  always @ (posedge clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      rw <= 1'd0;
    else begin
	  case(uart_state)
		UART_device: begin
		if(done)		
		rw <= data_r[0];
		end
		default: begin
		rw <= rw;
		end
	  endcase
    end
  end

  always @ (posedge clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      reg_addr <= 8'd0;
    else begin
	  case(uart_state)
		UART_address: begin
		if(done)	
		reg_addr <= data_r;
		end
		default: begin
		reg_addr <= reg_addr;
		end
	  endcase
    end
  end
  
  always @ (posedge clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      i2c_data <= 16'd0;
    else begin
	  case(uart_state)
		UART_data1: begin
		if(done)	
		i2c_data[15:8] <= data_r;
		end
		UART_data2: begin
		if(done)	
		i2c_data[7:0] <= data_r;
		end		
		default: begin
		i2c_data <= i2c_data;
		end
	  endcase
    end
  end  
 
endmodule