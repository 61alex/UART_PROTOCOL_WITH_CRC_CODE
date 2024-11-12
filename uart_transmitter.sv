// The value of clks_per_bit is derived by dividing the system clock frequency by the UART baud rate.
// Example for 10 MHz clock and 9600 baud rate: clks_per_bit = 10,000,000 / 9600 = 1042
module UART_Transmitter (
    input wire clk,              // System clock input
    input wire rst,              // Active high reset signal
    input wire [7:0] data_in,    // 8-bit data input to be transmitted
    input wire tx_start,         // Signal to start the transmission process
    output reg tx,               // Serial data output
    output wire tx_done          // Transmission complete signal
);
    
    localparam clks_per_bit = 1042;  // Clock cycles per bit

    // State definitions for FSM (Finite State Machine)
    localparam TX_IDLE = 3'b000,        // Idle state
               START_SIGNAL = 3'b001,   // Start bit state
               TX_DATA = 3'b010,       // Data transmission state
               TX_CRC = 3'b011,          // CRC transmission state
               TX_STOP = 3'b100;         // Stop bit state

    reg [2:0] tx_state = TX_IDLE;              // Current state of the FSM
    reg [2:0] bit_index;                       // Bit index for data transmission
    reg [12:0] clk_count;                       // Clock count for baud rate since 1042 contains aprox 11bits
    reg tx_done_reg = 0;                       // Register for transmission complete signal
    reg [3:0] crc_out;                         // Final CRC output
	 
    always @(posedge clk) begin
	      
        if (tx_start) begin
            crc_out <= compute_crc({data_in, 4'b0000}); // Concatenate data_in with 4'b0000 and compute CRC
				
        end
		
    end
	 
	 
    // Polynomial for CRC (x^4 + x + 1) represented in binary
    // This corresponds to 5'b10011
    function [3:0] compute_crc;
        input [11:0] data_crc; // 12-bit input: 8-bit data + 4-bit zero padding for CRC

        reg [11:0] remainder; // Remainder register
        integer i;

        begin
            // Initialize remainder with the 12-bit input
            remainder = data_crc;

            // Perform binary division
            for (i = 11; i >= 4; i = i - 1) begin
                // If the current leftmost bit is 1, perform XOR with the polynomial
                if (remainder[i] == 1) begin
                    remainder[i -: 5] = remainder[i -: 5] ^ 5'b10011;
                end
            end

            // The remainder is the last 4 bits after the division = crc_code
            compute_crc = remainder[3:0];
        end
    endfunction
	 
     
    always @(posedge clk) begin
        if (rst) begin
            tx <= 1'b1;                  // Idle state for TX line
            bit_index <= 3'b000;         // Initialize bit index
            clk_count <= 0;              // Initialize clock count
            tx_done_reg <= 0;            // Initialize transmission done signal
            tx_state <= TX_IDLE;         // Reset to idle state
        end 
		  else begin
            case (tx_state)
                TX_IDLE: begin
                    tx <= 1'b1;              // TX line idle (high)
                    tx_done_reg <= 0;       // Reset tx_done_reg
                    if (tx_start) begin
                       
                        
			               clk_count <= 0;
                        tx_state <= START_SIGNAL; // Move to start signal state
                    end
                end // end for TX_IDLE
                
                START_SIGNAL: begin
                    tx <= 1'b0;                  // Start bit (low)
                    if (clk_count < clks_per_bit) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;              // Reset clock count
                        bit_index <= 0;              // Reset bit index
                        tx_state <= TX_DATA;   // Move to data transmission state
                    end
                end // end for START_SIGNAL
                     
                TX_DATA: begin
                    tx <= data_in[bit_index];
                    if (clk_count < clks_per_bit) begin
                        clk_count <= clk_count + 1;
								 tx_state <= TX_DATA;
                    end else begin
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
									 clk_count<= 0;
									 tx_state <= TX_DATA;
                        end else begin
									 clk_count <= 0;
                            bit_index <= 0;
                            tx_state <= TX_CRC; // Move to CRC transmission state
                        end
                       
                    end
                end // end for TX_DATA_STATE
                     
                TX_CRC: begin
                    tx <=  crc_out[bit_index];
                    if (clk_count < clks_per_bit) begin
                        clk_count <= clk_count + 1;
			               tx_state <= TX_CRC;
                    end else begin
                        if (bit_index < 3) begin
                            bit_index <= bit_index + 1;
                            clk_count <= 0; // Reset clock count
                             tx_state <= TX_CRC;
                        end else begin
                            clk_count <= 0; // Reset clock count
                            bit_index <= 0;  
                            tx_state <= TX_STOP; // Move to stop state
                        end
                        
                    end
                end // end for TX_CRC
                     
                TX_STOP: begin
                    tx <= 1'b1; // Stop bit (high)
                    if (clk_count < clks_per_bit) begin
                        clk_count <= clk_count + 1;
								tx_state <= TX_STOP;
                    end else begin
                        tx_done_reg <= 1'b1; // Signal that transmission is done
                        clk_count <= 0;
								bit_index <= 0;
                        tx_state <= TX_IDLE; // Reset to idle state
                    end
                end // end for TX_STOP
                
                default: 
                    tx_state <= TX_IDLE; // Reset to idle state on unexpected condition
            endcase
        end
    end // end of always block

    assign tx_done = tx_done_reg; // Assign to tx_done output

endmodule
