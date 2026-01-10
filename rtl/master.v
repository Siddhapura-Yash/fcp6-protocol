module master2(input clk,
              input rst,
              input start,
              input [7:0]header_in,
              input [7:0]data_in,
              inout [1:0]data,
              inout ack,
              inout [1:0]ctrl,
              output reg busy);
  
  parameter [3:0] IDLE = 4'b0000,TAKE_BUS = 4'b0001, SEND_HEADER = 4'b0010, WAIT_ACK = 4'b0011, DECIDE = 4'b0100, SEND_DATA= 4'b0101, SEND_ACK  = 4'b0110, RELEASE_CTRL_BUS = 4'b0111, RECEIVE_DATA = 4'b1000, STOP = 4'b1001, DONE = 4'b1010, RECEIVE_ACK = 4'b1011;
  
  //Remaining state
 
  
  reg [3:0]state;
  reg [7:0]header_data;
  reg [2:0]count; //inside take_bus state for header transmission
  reg [7:0]read_data; //reading from slave 
  reg [7:0]saved_data = 8'b10011001; //will use for writing to slave
  reg [2:0]header_count;
  reg ack_enable;
  reg ack_out;
  reg [1:0]ctrl_out;
  reg ctrl_enable;
  
  reg [1:0]data_out;
  reg data_enable;
  
  //FSM LOGIC
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      state <= IDLE;
      busy <= 0;
    end
    else begin
	busy <= (state != IDLE);

      case(state) 
        IDLE : begin
          if(start) begin
            state <= TAKE_BUS;
            header_data <= header_in;
            header_count <= 6;
            saved_data <= data_in;
          end
          else begin
            state <= IDLE;
          end
        end
        
        TAKE_BUS : begin
          state <= SEND_HEADER;
          count <= 6;
        end
        
        SEND_HEADER : begin
          if(header_count == 0) begin	//if count = 0 means we have send all the header data  
          	state <= WAIT_ACK;
          end
          else begin	
            header_count <= header_count - 2;
//             header_count <= (header_count >= 2) ? header_count - 2 : 0;
			state <= SEND_HEADER;
          end
        end
        
        WAIT_ACK : begin
          if(ack == 0) begin
            count <= 6;
            state <= DECIDE;
          end
          else if(ack == 1) begin
            state <= STOP;
          end
        end
        
        DECIDE : begin
          if(header_data[0] == 0) begin	//0 = read
            state <= RELEASE_CTRL_BUS;
          end
             else if(header_data[0]) begin
               state <= SEND_DATA;
             end
        end
             
         SEND_DATA : begin	//Write operation
           if(count == 0) begin
             state <= RECEIVE_ACK;
           end
           else begin
//              count <= count - 2;
             count <= (count >= 2) ? count - 2 : 0;

             state <= SEND_DATA;
           end
         end
             
         RELEASE_CTRL_BUS : begin
           state <= RECEIVE_DATA;
         end
		
         RECEIVE_ACK : begin
           if(ack == 0) begin
// 			state <= STOP;	//we are intially sending 1 byte
             state <= DONE;
           end
           else if(ack == 1) begin
             state <= SEND_DATA;
           end
		 end
             
          RECEIVE_DATA : begin	//Read operation
            if(header_data[0] == 0) begin	//again cheking for R/W operation
            read_data[count +: 2] <= data;
              if(count == 0) begin
                state <= SEND_ACK;
              end
              else begin
//                 count <= count - 2;
                count <= (count >= 2) ? count - 2 : 0;

                state <= RECEIVE_DATA;
              end
              end
            end
             
           SEND_ACK : begin	//data received successfully
             state <= STOP;
           end
             
             STOP : begin
               if(ctrl == 2'b11) begin //end of communication
               		state <= DONE;
             	end
               else if(header_data[0] == 0) begin	//slave still sending data
                   state <= RECEIVE_DATA;
                 count <= 6;
             	end
               else if(header_data[0] == 1) begin //master still want to send data
                   state <= SEND_DATA;
                 count <= 6;
             	end
				else begin
                	state <= DONE;
             	end
			  end
             
             DONE : begin
               state <= IDLE;
             end
        default : state <= IDLE;
      endcase
    end
  end
        
             
             //tri - state logic
             always@(negedge clk or posedge rst) begin
               if(rst) begin
                 data_enable <= 0;
                 ack_enable <= 0;
                 ctrl_enable <= 0;
                 ctrl_out <= 0;
                 ack_out <= 0;
                 data_out <= 2'b00;
               end
               else begin
                 case(state) 
                   
                   IDLE : begin
                     header_count <= 4;
                   end
                   
                   TAKE_BUS : begin
                     data_enable <= 1;
                     ctrl_out <= 2'b01;
                     ctrl_enable <= 1;
                 	 ack_enable <= 0;
                     data_out <= header_data[count +: 2];
                   end
                   
                   SEND_HEADER : begin
                     data_out <= header_data[header_count +: 2];
                     data_enable <= 1;
                     ctrl_out <= 2'b01;
                     ctrl_enable <= 1;
                     ack_enable <= 0;
                   end
                   
                   WAIT_ACK : begin
                     data_enable <= 0;
                     ack_enable <= 0;
                     ctrl_enable <= 1;
					 ctrl_out <= 2'b01;
                   end
                   
                   DECIDE : begin
                     if(header_data[0] == 0) begin //we are reading
                       data_enable <= 0;
                 	   ack_enable <= 0;
                 	   ctrl_enable <= 0;
                     end
                     else if (header_data[0]) begin //write
                       data_enable <= 1;
                       ctrl_out <= 2'b01;
                       ctrl_enable <= 1;
                       ack_enable <= 0;
                     end
                   end
                        
					SEND_DATA : begin
                      data_out <= saved_data[count +: 2];
                      data_enable <= 1;
                      ctrl_out <= 2'b01;
                      ctrl_enable <= 1;
                      ack_enable <= 0;
                    end
                        
                     RELEASE_CTRL_BUS : begin //releasing bus while reading
                        data_enable <= 0;
                        ack_enable <= 0;
                        ctrl_enable <= 0;
                     end
                        
					RECEIVE_ACK : begin
						data_enable <= 0;
                        ack_enable <= 0;
                        ctrl_enable <= 1;
                        ctrl_out <= 2'b11;
					end
                     
                     RECEIVE_DATA : begin
                         data_enable <= 0;
                         ack_enable <= 0;
                         ctrl_enable <= 0;
                     end
                        
                     SEND_ACK : begin
                         data_enable <= 1;
                         ack_enable <= 1;
                       	 ack_out <= 1;
                         ctrl_enable <= 1;
                         ctrl_out <= 2'b01;
                     end
                        
					 STOP : begin
                       if(ctrl == 2'b11) begin //end of communication
                         data_enable <= 0;
                         ctrl_out <= 2'b11;
                         ctrl_enable <= 1;
                       end
					   else if(ctrl == 2'b10) begin	//slave still sending data
//                           count <= 6;
                          data_enable <= 0; 
                        end
                       else if(ctrl == 2'b01) begin //master still want to send data
//                          count <= 6;
                         data_enable <= 1;
                         ctrl_out <= 2'b01;
                       ctrl_enable <= 1;
                       end
                     end
                        
                     DONE : begin
                       data_enable <= 0;
                       ctrl_enable <= 0;
                       ack_enable <= 0;
                     end
                   
                 default: begin
                  data_enable <= 0;
                  ack_enable  <= 0;
                  ctrl_enable <= 0;
                  ctrl_out    <= 2'b00;
                end
                 endcase
               end
             end
             
             
        
		assign data =(data_enable) ? data_out : 'bz;
// 		assign busy = (state == IDLE) ? 0 : 1;
		assign ack = (ack_enable) ? ack_out : 'bz;
		assign ctrl = (ctrl_enable) ? ctrl_out : 'bz;
                   
// assign data = (data_enable && ctrl == 2'b01) ? data_out : 'bz;
// assign ack  = (ack_enable  && ctrl == 2'b10) ? ack_out  : 'bz;
// assign ctrl = (ctrl_enable) ? ctrl_out : 'bz;

endmodule
