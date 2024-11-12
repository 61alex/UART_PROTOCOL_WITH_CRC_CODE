
// The value of clks_per_bit is derived by dividing the system clock frequency by the UART baud rate.
// Example for 10 MHz clock and 9600 baud rate: clks_per_bit = 10,000,000 / 9600 = 1042

module uart_top(
	input wire clk,              // System clock input (e.g., 10 MHz)
	input wire rst,              // Reset signal, active high
	input wire [7:0] data_in,    // 8-bit parallel data to be transmitted
	input wire tx_start,         // Start signal for transmission
	input wire rx,               // Serial data input for receiving
	output wire tx,              // Serial data output for transmitting
	output wire tx_done,         // Transmission done signal
	output wire [7:0] data_out,  // 8-bit parallel data received from rx
	output wire crc_error      // CRC error flag for received data
);

    // Instantiate the UART Transmitter module with the defined clks_per_bit parameter.
	 
UART_Transmitter UUT(
	.clk(clk),               // Connects the system clock to the transmitter
	.rst(rst),               // Connects the reset signal to the transmitter
	.data_in(data_in),       // Connects the 8-bit data input to the transmitter
	.tx_start(tx_start),     // Connects the transmission start signal to the transmitter
	.tx(tx),                 // Transmitter output line (serial data out)
	.tx_done(tx_done)        // Transmission complete indicator
);

    // Instantiate the UART Receiver module with the defined clks_per_bit parameter.
 
UART_Receiver UUR(
	.clk(clk),               // Connects the system clock to the receiver
	.rst(rst),               // Connects the reset signal to the receiver
	.rx(rx),                 // Connects the serial data input line to the receiver
	.data_out(data_out),     // Outputs the 8-bit parallel data received
	.crc_error(crc_error)    // Sets the CRC error flag if an error is detected in received data
);

endmodule
