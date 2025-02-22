
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   		clk;
input   		reset;
output  [13:0] 	gray_addr;
output         	gray_req;
input   		gray_ready;
input   [7:0] 	gray_data;
output  [13:0] 	lbp_addr;
output  		lbp_valid;
output  [7:0] 	lbp_data;
output  		finish;

//====================================================================
parameter state_IDLE =2'd0;
parameter state_INPUT=2'd1;
parameter state_CALCULATE =2'd2;
parameter state_OUTPUT =2'd3;
reg [1:0] current_state, next_state;
reg [13:0] 	gray_addr;
reg 		gray_req,lbp_valid,finish;

reg [7:0] lbp_data;
reg [13:0] lbp_addr=14'd0,next_lbp_addr;
reg [7:0] next_lbp_data;
reg [7:0] gc, g0, g1, g2, g3, g4, g5, g6, g7;
reg [6:0] column_count;
reg [7:0] data_array[127:0][127:0];
reg [7:0] lbp_value[15876:0];

reg [13:0]i,j,lbp_count,x,y,temp;
reg [13:0] row_count;
//============================code here===============================

//FSM
always@(posedge clk or posedge reset) begin
	if(reset)
		current_state <= state_INPUT;
	else
		current_state <= next_state;
end

always @(*) begin
    case(current_state)
        state_INPUT: begin
            if(column_count==14'd127&row_count==14'd127)
                next_state=state_CALCULATE;
            else
                next_state=state_INPUT;
        end
        state_CALCULATE: 
            next_state=state_OUTPUT;
               
        state_OUTPUT:
            next_state=state_OUTPUT;
        state_IDLE: next_state=state_IDLE;
   endcase
end
//input
always@(posedge clk or posedge reset) begin
	if(reset) gray_req <= 1'b0;
	else begin
		if(gray_ready) gray_req <= 1'b1;
		else gray_req <= 1'b0;	
	end
end

always@(posedge clk or posedge reset) begin
    if( reset) gray_addr=-14'd1;
    else if(gray_ready)begin
            gray_addr<=gray_addr+14'd1;
    end
    else
        gray_addr<=gray_addr;
end

always@(posedge clk or posedge reset) begin
        if(reset) begin
            row_count<=-14'd1;
            column_count<=-7'd1;
            for(i=0;i<=14'd127;i=i+1)begin
                for(j=0;j<=14'd127;j=j+1) begin
                    data_array[i][j]<=0;
                end
            end            
        end
        else if(gray_ready)begin
            data_array[row_count][column_count]<=gray_data;
            if(column_count==7'd127) begin
                column_count<=7'd0;
                row_count<=row_count+14'd1;
            end
            else
                column_count<=column_count+14'd1;
        end
        else begin
            row_count<=row_count;
            column_count<=column_count;
            for(i=0;i<=14'd127;i=i+1)begin
                for(j=0;j<=14'd127;j=j+1) begin
                    data_array[i][j]<=data_array[i][j];
                end
            end
        end
end 

//calculate
always @(*) begin
    if(current_state==state_CALCULATE) begin
        lbp_count=14'd129;
        lbp_value[0]=14'd0;
        for(i=14'd1;i<=14'd15876;i=i+1)begin
			x={lbp_count[6],lbp_count[5],lbp_count[4],lbp_count[3],lbp_count[2],lbp_count[1],lbp_count[0]};
			y={lbp_count[13],lbp_count[12],lbp_count[11],lbp_count[10],lbp_count[9],lbp_count[8],lbp_count[7]};
			g0=data_array[y-7'd1][x-7'd1];
			g1=data_array[y-7'd1][x];
			g2=data_array[y-7'd1][x+7'd1];
			g3=data_array[y][x-7'd1];
			gc=data_array[y][x];
			g4=data_array[y][x+7'd1];
			g5=data_array[y+7'd1][x-7'd1];
			g6=data_array[y+7'd1][x];
			g7=data_array[y+7'd1][x+7'd1];
			
			if(g0<gc) lbp_value[i][0] = 1'b0;
			else lbp_value[i][0] =1'b1;
        
			if(g1<gc) lbp_value[i][1] = 1'b0;
			else lbp_value[i][1] =1'b1; 
			
			if(g2<gc) lbp_value[i][2] = 1'b0;
			else lbp_value[i][2] =1'b1;                
			
			if(g3<gc) lbp_value[i][3] = 1'b0;
			else lbp_value[i][3] =1'b1;         
        
			if(g4<gc) lbp_value[i][4] = 1'b0;
			else lbp_value[i][4] =1'b1;         
        
			if(g5<gc) lbp_value[i][5] = 1'b0;
			else lbp_value[i][5] =1'b1;         
        
			if(g6<gc) lbp_value[i][6] = 1'b0;
			else lbp_value[i][6] =1'b1;
        
			if(g7<gc) lbp_value[i][7] = 1'b0;
			else lbp_value[i][7] =1'b1;
        
			if(lbp_count[6]&lbp_count[5]&lbp_count[4]&lbp_count[3]&lbp_count[2]&lbp_count[1])
				lbp_count=lbp_count+3;
			else
				lbp_count=lbp_count+1;
        end          
    end
end       
    
always@(posedge clk or posedge reset) begin
	if(reset) lbp_valid <= 1'b0;
	else if(current_state == state_OUTPUT)begin
		lbp_valid <= 1'b1;
	end
	else lbp_valid <= 1'b0;
end

always@(posedge clk or posedge reset) begin//這裡
	if(reset) lbp_addr <= 14'd127;
	else lbp_addr <= next_lbp_addr;
end


always@(posedge clk or posedge reset) begin
	if(reset) lbp_data <= 8'd0;
	else lbp_data <= next_lbp_data;
end

always@(*) begin
	if(lbp_valid) begin
		if(lbp_addr[6] & lbp_addr[5] & lbp_addr[4] & lbp_addr[3] & lbp_addr[2] & lbp_addr[1]&(lbp_addr!=14'd127)) 
			next_lbp_addr = lbp_addr + 14'd3;
	    else if(lbp_addr>14'd16254) lbp_addr=14'd16254;//應把這一行搬到上面
		else next_lbp_addr = lbp_addr + 14'd1;
	end
	else next_lbp_addr = lbp_addr;
end

always@(posedge clk or posedge reset) begin
    if(reset) temp<=14'd0;
    else if (lbp_valid&temp<=14'd15875) begin
        temp<=temp+14'd1;
    end
end

always@(*) begin
    next_lbp_data=lbp_value[temp];//用lbp_value[temp[6:0]]較好
end

always@(posedge clk or posedge reset) begin
	if(reset) finish <= 1'b0;
	else begin
		if(lbp_addr == 14'd16254)
			finish <= 1'd1;
		else
			finish <= 1'd0;
	end
end
//====================================================================
endmodule