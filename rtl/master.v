module master(input clk,
              input rst,
              input start,
              input [7:0]header_in,
              input [7:0]data_in,
              inout [1:0]data,
              inout ack,
              inout [1:0]ctrl,
              output reg busy);
  
  parameter [3:0] IDLE = 3'b0000,TAKE_BUS = 3'b0001, SEND_HEADER = 3'b0010, WAIT_ACK = 3'b0011, DECIDE = 3'b0100, SEND_DATA= 3'b0101, RECEIVE_DATA = 3'b0110, RELEASE_CTRL_BUS = 3'b0111, RECEIVE_DATA = 3'b1000, STOP = 3'b1001, DONE = 3'b1010;
  
  reg [3:0]state;
  reg [7:0]header_data;
  reg [2:0]header_count = 0;
  reg [7:0]memory[63:0]; //8 bit with 64 location used for receive data
  reg [2:0]count;
  reg stop_done;
  reg [2:0]send_count;
    
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      data <= 0;
      busy <= 0;
      state <= IDLE;
    end
	else begin
      case(state) 
        IDLE : begin
          if(start) begin
            state <= TAKE_BUS;
          end
        end
        
        TAKE_BUS : begin
          state <= SEND_HEADER;
          header_count <= 6;
        end
        
        SEND_HEADER : begin
          if(header_count == 0) begin	//if count = 0 means we have send all the data and go for ACK 
          	state <= WAIT_ACK;
          end
          else begin	
            header_count <= header_count - 2;
          end
        end
        
        WAIT_ACK : begin
          if(ack) begin
            state <= DECIDE;
          end
        end
        
        DECIDE : begin
          if(header_in[0] == 0) begin	//read operation
            state <= RELEASE_CTRL_BUS;
          end
          else begin					//write operation
            state <= SEND_DATA;
            count <= 7;
          end
        end
        
        SEND_DATA : begin
          if(ctrl == 01) begin
              if(location < 63) begin
                if(send_count == 0) begin
                   send_count <= 7;
                   location = location + 1;
              	 end
               end
              else begin
                send_count <= send_count + 2;
              end
		  end
          else if(ctrl == 11) begin
            state <= stop;
            stop_done <= 1;
          end
        end
        
		RELEASE_CTRL_BUS : begin
          state <= RECEIVE_DATA;
          ctrl <= 10;
          release_bus <= 1;	//not implemented yet (for assign at the end)
          location <= 0;
          count <= 0;
        end
        
        RECEIVE_DATA : begin
          if(ctrl == 2'b10) begin
            if(location < 63) begin
              if(count <= 7) begin
                 memory[location][count +: 2] <= data[1:0];
                  if(count == 7) begin  // Move pointer
                    count <= 0;           // next frame
                    location <= location + 1;
                  end
                  else begin
                    count <= count + 2;
                  end
              end
            end
          end
          else if(ctrl == 11) begin
            state <= STOP;
            stop_done <= 1;
          end
        end
        
        STOP : begin
          if(stop_done == 1) begin
            state <= DONE;
          end
        end
        
        DONE : begin
          state <= IDLE;
        end

    end
  end
        
        always@(negedge clk) begin
          case(state)
            IDLE : begin
              
            end
            
            
            TAKE_BUS : begin
              
            end
            
            
            SEND_HEADER : begin
              data[1:0] <= header_data[header_count +: 2];	//header_data[start_index +: width]	
            end
            
            
            WAIT_ACK : begin
              
            end
            
            
            DECIDE : begin
              if(header_in[0] == 0) begin	//read operation
                
              end
              else begin					//write operation
                data <= saved_data[location][count +: 2];
              end
            end 
            
            
            SEND_DATA : begin
              data <= memory[location][send_count +: 2];
            end
            
            
            RECEIVE_DATA : begin
              
            end
            
            
			STOP : begin
              if(ctrl == 11) begin
                
              end
        	end
        
            
        	DONE : begin
          	  
        	end
            
          
        end
