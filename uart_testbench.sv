
`timescale 1ns / 1ps 
module UART_TESTBENCH;
	 
  // Testbench uses a 10 MHz clock
  // Want to interface to 9600 baud UART
  // 10000000 / 9600 = 1042 Clocks Per Bit.

	reg  clk =0 ;      // clk default Low      
	reg  rst = 0 ;      // reset(rst) default Low         
	reg  [7:0] data_in ;    // 8_bits data to be sent via line tx
	reg  tx_start ;         // Signal for transmission to start
	reg  rx = 1 ;           
	wire tx;              
	wire tx_done;         
	wire [7:0] data_out; 
	wire crc_error;  
     

  
     // Clock and Baud rate parameters
    parameter CLK_PERIOD = 100; // 10 MHz clock  localparam used in submodule clks_per_bit = 1042; Baud rate tick for 9600 baud
   
    parameter c_BIT_PERIOD = 104167; // time in nano seconds to send 1_bit of data at clk 0f 10MHZ and Baud rate of 9600 
	 
   uart_top UUT(
	.clk(clk),               // Connects the system clock to the transmitter
	.rst(rst),               // Connects the reset signal to the transmitter
	.data_in(data_in),       // Connects the 8-bit data input to the transmitter
	.tx_start(tx_start),     // Connects the transmission start signal to the transmitter
	.tx(tx),                 // Transmitter output line (serial data out)
	.tx_done(tx_done),        // Transmission complete indicator
        .rx(rx),                 // Connects the serial data input line to the receiver
	.data_out(data_out),     // Outputs the 8-bit parallel data received
	.crc_error(crc_error)   // Sets the CRC error flag if an error is detected in received data
	);
   

 // Generate a 10 MHz clock
    always #(CLK_PERIOD / 2) clk = ~clk;

   
 
  // Takes in input byte and serializes it 
  task UART_WRITE_BYTE;
    input [11:0] i_Data;    // { CRC_CODE(4_BITS),data_in(8_BITS)} Concatenated
    integer     ii;        
    begin
       
      // Send Start Bit
      rx <= 1'b0;
      #(c_BIT_PERIOD);
      
        
      // Send Data Byte and CRC
      for (ii=0; ii<11; ii=ii+1)
        begin
          rx <= i_Data[ii];
          #(c_BIT_PERIOD);
        end
        
      // Send Stop Bit
      rx <= 1'b1;
      #(c_BIT_PERIOD);
     end
  endtask 
   
  
  // Main Testing:
  initial
    begin
       
      // Tell UART to send a command (exercise Tx)
      @(posedge clk);
      @(posedge clk);
      tx_start <= 1'b1;
      // For 8'b3F (binary 0011 1111): CRC = 4'b0101 (or decimal 5) for wave form verification on tx wire
      data_in <= 8'h3F;
      @(posedge clk);
      tx_start <= 1'b0;
      @(posedge tx_done);
        
      // Send a command to the UART (exercise Rx)
  
    //   @(posedge clk); // ( WITH_OUT ANY CRC OR DATA BITS ERROR) (Instruction ---> comment out to test 1 at a time}
                    // For 8'b3F (binary 0011 1111): CRC = 4'b0101 (or decimal 5) for wave form verification on rx wire
     //  UART_WRITE_BYTE(12'b0101_0011_1111);	// with_out crc_error concatenated  { 4_bits crc + 8_bits}
    
       // (Instruction ---> comment out to test 1 at a time}
   // @(posedge clk);  // ( WITH CRC ERROR ) For 8'b3F (binary 0011 1111): CRC = 4'b0101 (or decimal 5) for wave form verification on rx wire
   //    UART_WRITE_BYTE(12'b0111_0011_1111);	// with crc_error concatenated { 4_bits crc + 8_bits}
    
         @(posedge clk);  // (WITH DATA BIT ERROR)
                        // For 8'b3F (binary 0011 1111): CRC = 4'b0101 (or decimal 5) for wave form verification on rx wire
       UART_WRITE_BYTE(12'b1010_0011_1011);	// with erorr in data bit  concatenated { 4_bits crc + 8_bits}
         end // End for Initail block
endmodule