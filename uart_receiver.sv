
// The value of clks_per_bit is derived by dividing the system clock frequency by the UART baud rate.
// Example for 10 MHz clock and 9600 baud rate: clks_per_bit = 10,000,000 / 9600 = 1042

module UART_Receiver (
    input wire clk,               // Clock input
    input wire rst,               // Reset input
    input wire rx,                // UART receive data
    output reg [7:0] data_out = 8'b0,    // 8-bit data outputs with default 0
    output reg crc_error          // CRC error flag
);

    localparam clks_per_bit = 1042; // Clock cycles per bit
	 
    // State definitions for FSM
    localparam RX_IDLE       = 3'b000, // Receiver stay idle when rx = 1 or High
               RX_START      = 3'b001, //  Receiver moves to start when rx = 0 or Low
               RX_DATA_TX    = 3'b010,  // This state receive the actual 8_bits data sent
               RX_CRC        = 3'b011,   // This state receives the 4_bits crc code 
               RX_STOP       = 3'b100;   // Stops receiving  and set rx = 1 or High

    
    reg [2:0] rx_state = RX_IDLE;    // Current state of the FSM
    reg [2:0] bit_index;           // Bit index for data reception
    reg [12:0]clk_count;           // Clock count for baud rate
    reg [7:0] data_reg;            // Register to hold received data
    
    reg r_Rx_Data_R = 1'b1;   // rx_register for metastability in transmission line
    reg r_data = 1'b1;        // rx_register for metastability in transmission line
	 
    reg [3:0] crc_reg;             // Register to hold received 4-bit CRC code
    reg [3:0] computed_crc;        // Computed 4-bit CRC for verification
	 
	 // Compute CRC on positive edge of rx_state == RX_STOP
    always @(posedge clk) begin
	 
        if (rx_state == RX_STOP) begin
           computed_crc <= check_crc({data_reg,crc_reg});
        end
		
    end
   
	
   // Polynomial for CRC (x^4 + x + 1) represented in binary (10011)
    function [3:0] check_crc;
        input [11:0] data_crc;  // 12-bit input: 8-bit data + 4-bit received CRC
        reg [11:0] remainder;   // Temporary remainder
        integer i;

        begin
            // Initialize remainder with the 12-bit input (data + crc)
            remainder = data_crc;

            // Perform binary division by polynomial 10011
            for (i = 11; i >= 4; i = i - 1) begin
                // If the current leftmost bit is 1, perform XOR with the polynomial
                if (remainder[i] == 1) begin
                    remainder[i -: 5] = remainder[i -: 5] ^ 5'b10011;
                end
            end

            // The remainder is the last 4 bits after the division
            check_crc = remainder[3:0];
        end
    endfunction
	 
	 
    // Purpose: Double-register the incoming data.
	 // This allows it to be used in the UART RX Clock Domain.
  // (It removes problems caused by metastability)
  
    always @(posedge clk) begin
        r_Rx_Data_R <= rx;
        r_data <= r_Rx_Data_R;
		  end
    
    always @(posedge clk) begin
	 
        if (rst) begin    // Reset the receiver to default setting
            rx_state <= RX_IDLE;
            clk_count <= 0;
            bit_index <= 0;
            crc_error <= 0;
	        data_out <= 8'b0;
        end 
		  
		  else begin  
				case (rx_state)
                RX_IDLE: begin
                    crc_error <= 0;  
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if (r_data == 1'b0) begin // Check if rx line goes from High (1) to Low (0) to start receiving data
                        rx_state <= RX_START;
						  end
						  end // END CASE: FOR RX_IDLE
                 
					 RX_START : begin
							if(clk_count < (clks_per_bit)/2) begin  // Start checking data at the middle of the data_clock clks_per_bit
							   clk_count <= clk_count + 1;
								end
								else begin
								if (r_data == 1'b0)begin
									bit_index <= 0;  // Change to default before change of state
									clk_count <= 0;  // Change to default before change of state
									rx_state <= RX_DATA_TX;
									end
									end
									end // END CASE FOR RX_START
									
					 
					 RX_DATA_TX : begin
						if (clk_count < clks_per_bit) begin //checking data at the middle of the data_clock clks_per_bit
							 clk_count<= clk_count + 1;   

							end
						
						else begin
								 
										data_reg[bit_index] <= r_data;    // Register to hold the received 8 _bits data
                 
									 // Check if we have received all bits
										if (bit_index < 7)
										begin
										  clk_count <= 0;
										  bit_index <= bit_index + 1;
										 rx_state   <=  RX_DATA_TX;
										end
										
									 else
										begin
										  clk_count <=0; // Change to default before change of state
										  bit_index <= 0; // Change to default before change of state
										  rx_state   <= RX_CRC;
										end
								  end
							 end // case: RX_DATA_TX
			 
			       RX_CRC : begin
			       
					 if (clk_count < clks_per_bit) begin
							 clk_count <= clk_count + 1;
							end
							
							else begin 
								 crc_reg[bit_index] <= r_data;
                                                      
							 // Check if we have received all bits
								if (bit_index < 3)
								begin
								  clk_count <= 0;
								  bit_index <= bit_index + 1;
								  rx_state   <=  RX_CRC;
								end
								
							 else
								begin
								  bit_index <= 0; // Change to default before change of state
								  clk_count <= 0;// Change to default before change of state
								  rx_state   <= RX_STOP;
								end
						  end
					 end // case: RX_CRC 
					 
																
				RX_STOP : begin
				     // Compute CRC

                 // Wait clks_per_bit clock cycles for Stop bit to finish
						if (clk_count < clks_per_bit)
							begin
								clk_count <= clk_count + 1;
								rx_state <= RX_STOP;
							end
					
					  	 else
							begin
							  
								if(r_data == 1'b1) begin  // Stop bit check
									if(computed_crc == 4'b0000) begin
										crc_error <= 1'b0;  // CRC mismatch error
										data_out <= data_reg;
										rx_state <= RX_IDLE;
										end
										
									else begin
										crc_error <= 1'b1; // No error
										data_out <= 8'b00000000;
										rx_state <= RX_IDLE;
										end
										end
			          	 end 
			             end // case:RX_STOP
							 
							default: 
								rx_state <= RX_IDLE;
						   endcase
					end // END OF CASE STATEMENT
				end // END OF ALWAYS 	
				
endmodule 


