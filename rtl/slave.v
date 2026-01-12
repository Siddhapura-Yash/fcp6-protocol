module slave(input clk,
             inout [1:0]ctrl,
             inout [1:0]data,
             inout ack);
  
//   assign start = (ctrl == 2'b01) ? 1 : 0;

  
    parameter [3:0] IDLE = 4'b0000, WASTE_ONE_CYCLE = 4'b0001, RECEIVE_HEADER = 4'b0010, SEND_ACK = 4'b0011, DECIDE = 4'b0100, TAKE_BUS = 4'b0101, SEND_DATA = 4'b0110, RECEIVE_DATA = 4'b0111, STOP = 4'b1000, DONE = 4'b1001, SEND_ACK2 = 4'b1010, RECEIVE_ACK = 4'b1011;
  
  reg [3:0]state = IDLE;
  reg [2:0]count = 6;
  reg [7:0]header_data;
  //   reg [7:0]saved_data = 8'd88;		//used while master reading
  //   reg [7:0]received_data;			//used when master writing
  reg [2:0]receive_count;
  
  reg [1:0]data_out;
  reg data_enable;
  reg ctrl_enable, ack_enable;
  reg [1:0] ctrl_out;
  reg ack_out;
  
  reg [7:0]read_memory[63:0];	//data will be stored in this memory
  reg [7:0]saved_data[63:0];	//from this memory data will be read by master

  reg [7:0]read_mem_inc = 0;	//used for reading
  reg [7:0]write_mem_inc = 0;	//used for writing
  	
  always@(posedge clk) begin
//     if(start) begin
   	  case(state)
        
        IDLE : begin
            if(ctrl == 2'b01) begin     // legal START frame
              state <= RECEIVE_HEADER;
              count <= 6;    
              saved_data[0] <= 8'd88;
            end
            else begin
              state <= IDLE;           // ignore floating bus
            end
          state <= WASTE_ONE_CYCLE;
		end
        
        WASTE_ONE_CYCLE : begin
          if(ctrl == 2'b01) begin
          state <= RECEIVE_HEADER;
          end
          else begin
            state <= WASTE_ONE_CYCLE;
          end
        end
        
      	RECEIVE_HEADER : begin
          header_data[count +: 2] = data;
          if(count == 0) begin
            state <= SEND_ACK;
          end
          else begin
            count = count - 2;
//             count <= (count >= 2) ? count - 2 : 0;
            state <= RECEIVE_HEADER;
          end
        end
        
        SEND_ACK : begin
          count <= 6;
          state <= DECIDE;
        end
        
        DECIDE : begin
          if(header_data[0] == 0) begin	//master reading
            state <= TAKE_BUS;
          end
          else if(header_data[0])begin	//master writing
            state <= RECEIVE_DATA;
            receive_count <= 6;
          end
        end
        
        TAKE_BUS : begin
          state <= SEND_DATA;
        end
        
        SEND_DATA : begin
          if(count == 0) begin	
            state <= RECEIVE_ACK;
            write_mem_inc <= write_mem_inc + 1;
          end
          else begin
            count <= (count >= 2) ? count - 2 : 0;
            state <= SEND_DATA;
          end
        end
        
        RECEIVE_ACK : begin 
          if(ack == 1) begin // 1 = NACK
            state <= SEND_DATA;
            count <= 6;
          end
          else if(ack == 0 && write_mem_inc > header_data[7:1]) begin
            state <= STOP;	//initially sending one byte
          end
          else if(ack == 0 && write_mem_inc <= header_data[7:1]) begin
            state <= SEND_DATA;	//initially sending one byte
            count <= 6;
          end
          else begin
            state <= RECEIVE_ACK;
          end
        end
        
        RECEIVE_DATA : begin
          read_memory[read_mem_inc][receive_count +: 2] <= data;
          if(header_data[0] == 1) begin //master reading
            if(receive_count == 0) begin
              state <= SEND_ACK2;
              read_mem_inc <= read_mem_inc + 1;
            end
            else begin
              receive_count <= receive_count - 2;
              state <= RECEIVE_DATA;
            end
          end
        end
        
        SEND_ACK2 : begin
//           state <= STOP;
//           count <= 6;
          if(header_data[7:1] > read_mem_inc) begin
               state <= RECEIVE_DATA;
               read_mem_inc <= read_mem_inc + 1;
			   receive_count <= 6;
             end
          else if(read_mem_inc >= header_data[7:1] ) begin
               state <= STOP;
               receive_count <= 6;
             end
        end
        
        STOP : begin	//chceking communication status
          if(ctrl == 2'b11) begin	//end of communication
            state <= DONE;
          end
          else if(header_data[0] == 1) begin	//master still sending data
//             state <= RECEIVE_DATA;
            state <= DONE;	//currently we are sending only 1 byte
          end
          else if(header_data[0] == 0) begin		//slave want to communicate
//             state <= SEND_DATA;
            state <= DONE;  //currently we are sending only 1 byte
          end
          else begin
            state <= DONE;
          end
        end
        
        DONE : begin
          state <= IDLE;
        end
        
        default: state <= IDLE;
//   	end
      endcase
  end
        
        
        //driving logic
        always@(negedge clk) begin
          case(state) 
            IDLE : begin
              //nothing to write
            end
            
          RECEIVE_HEADER : begin
            data_enable <= 0;
            ctrl_enable <= 0;
            ack_enable <= 0;
          end
            
           SEND_ACK : begin
             data_enable <= 0;
             data_out <= 0;
             ctrl_out <= 2'b10;
		     ctrl_enable <= 1;
             ack_enable <= 1;
             ack_out <= 0;
           end
            
            DECIDE : begin
              if(header_data[0] == 0) begin
                data_enable <= 1;
                ctrl_out <= 2'b10;
				ctrl_enable <= 1;
                ack_enable <= 0;
              end
              else if(header_data[0] == 1) begin
                data_enable <= 0;
                ctrl_out <= 0;
                ack_enable <= 0;
              end
            end
            
            TAKE_BUS : begin
              data_enable <= 1;
//               count <= 6;
              ctrl_out <= 2'b10;
			  ctrl_enable <= 1;
              ack_enable <= 0;
            end
            
            SEND_DATA : begin
              data_enable <= 1;
              data_out <= saved_data[write_mem_inc][count +: 2];
              ctrl_out <= 2'b10; 
			  ctrl_enable <= 1;
              ack_enable <= 0;
            end
            
            RECEIVE_ACK : begin
              data_enable <= 0;
              ack_enable <= 0;
              ctrl_enable <= 0;
              ctrl_out <= 2'b10;
            end
            
            RECEIVE_DATA : begin
              data_enable <= 0;
              ack_enable <= 0;
              ctrl_enable <= 0;
            end
            
            SEND_ACK2 : begin
              ack_enable <= 1;
              ack_out <= 0;
              ctrl_out <= 2'b10;
			  ctrl_enable <= 1;
            end
            
            STOP : begin
              if(ctrl == 2'b11) begin
                data_enable <= 0;
              end
              else if(ctrl == 2'b01) begin
                data_enable <= 0;
              end
              else if(ctrl == 2'b10) begin
                data_enable <= 1;
                ctrl_out <= 2'b10;
				ctrl_enable <= 1;
              end
            end
            
            DONE : begin
                data_enable <= 0;
                ctrl_enable <= 0;
                ack_enable  <= 0;
                ctrl_out    <= 2'b00;
                ack_out     <= 0;
              	count <= 6;
            end
            
          default: begin 
              data_enable <= 0;
              ctrl_enable <= 0;
              ack_enable  <= 0;
          end
          endcase
        end
            
            assign data = (data_enable) ? data_out : 'bz;
            assign ack = (ack_enable) ? ack_out : 'bz;
            assign ctrl = (ctrl_enable) ? ctrl_out : 'bz;
            
endmodule
