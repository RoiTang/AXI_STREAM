`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/13 19:00:55
// Design Name: 
// Module Name: testbench
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

module tb_axi_stream_insert_header; 
    parameter PERIOD = 10 ; 
    parameter DATA_WD = 32 ; 
    parameter DATA_BYTE_WD = DATA_WD / 8 ; 		
    
    reg   clk                                = 0;
    reg   rst_n                              = 0;
    // axi_stream_insert_header Inputs
    reg   valid_in                           = 0;
    reg   last_in                            = 0;
    reg   [DATA_WD-1 : 0]  data_in           = 0;
    reg   [DATA_BYTE_WD-1 : 0]  keep_in      = 0;
  
    reg   [DATA_WD-1 : 0]  header_insert     = 0;
    reg   [DATA_BYTE_WD-1 : 0]  keep_insert  = 0;
    reg   ready_out                          = 0;
    reg   valid_insert                       = 0;
    
    // axi_stream_insert_header Outputs
    wire  [DATA_WD-1 : 0]  data_out;
    wire  [DATA_BYTE_WD-1 : 0]  keep_out;
    wire  last_out;
    wire  ready_insert; 
    wire  ready_in;
    wire  valid_out;
    
    //���������	
	integer seed;
	initial
	begin
		seed = 2;
	end
    
    //����ʱ���ź�
	initial
    begin
        forever #(PERIOD/2)  clk = ~clk;
    end
    
    //����reset�ź�
    initial
    begin
        #(PERIOD*2) rst_n = 1;
    end
    
    //ģ������
    axi_stream_insert_header #(
    .DATA_WD      (DATA_WD),
    .DATA_BYTE_WD (DATA_BYTE_WD))
    
    u_axi_stream_insert_header(
    .clk                     (clk),
    .rst_n                   (rst_n),
    .valid_in                (valid_in),//�����ź�
    .ready_in                (ready_in),//�����ź�
    .data_in                 (data_in [DATA_WD-1 : 0]),
    .keep_in                 (keep_in [DATA_BYTE_WD-1 : 0]),
    .last_in                 (last_in), 
    
    .valid_insert            (valid_insert),//�����ź�
    .ready_insert            (ready_insert),//�����ź�
    .header_insert           (header_insert [DATA_WD-1 : 0]),
    .keep_insert             (keep_insert [DATA_BYTE_WD-1 : 0]),
    
    .ready_out               (ready_out),//�����ź�
    .valid_out               (valid_out),//�����ź�
    .data_out                (data_out [DATA_WD-1 : 0]),
    .keep_out                (keep_out [DATA_BYTE_WD-1 : 0]),
    .last_out                (last_out)
    );
    
	//�������������valid�����ź�
    always @(posedge clk or negedge rst_n)
     begin
        if (!rst_n) 
        begin
			valid_in <= 0;
		    valid_insert <=0;
		end
		else
		begin 	
		 	valid_in <= {$random(seed)}%2;
		 	valid_insert <= {$random(seed)}%2;
        end    
     end
    //�������keep_insert�ź�
    integer insert_temp;
    initial 
    insert_temp = {$random(seed)}%5;
    
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            keep_insert <= 0;
        else if(valid_insert)
            case(insert_temp)
                4: keep_insert <= 4'b0000;
                3: keep_insert <= 4'b0001;
                2: keep_insert <= 4'b0011;
                1: keep_insert <= 4'b0111;
                0: keep_insert <= 4'b1111;
                default: keep_insert <= 4'b0000;
            endcase
     end
     
    //���ֹ��̣����valid��Ч��ready��Ч��data_in��ֵ
    always @(posedge clk or negedge rst_n) 
    begin
        if(!rst_n)
            data_in <= 'h0;
        else if(!valid_in) 
            begin
                data_in <= 'h0;
            end
            else if(valid_in)
                 begin
                    data_in <= $random(seed);           
                    last_in <= {$random(seed)}%2;
                 end              
    end
    
    always @(posedge clk or negedge rst_n) 
    begin
        if(!rst_n)
            data_in <= 'h0;
        else if(!valid_insert) 
            begin
                header_insert <= 'h0;
            end
            else if(valid_insert)
                 begin
                    header_insert <= $random(seed);
                 end              
    end
    
    //�������keep_in�ź�
    integer in_temp;
    initial
    in_temp = {$random(seed)}%4;
    
    always @(posedge clk or negedge rst_n) 
    begin
        if(!rst_n) 
            keep_in <= 0;
        else if(ready_in)
            case(in_temp)
                3: keep_in <= 4'b1000;
                2: keep_in <= 4'b1100;
                1: keep_in <= 4'b1110;
                0: keep_in <= 4'b1111;
                default: keep_in <= 4'b1111;
            endcase
    end        
    
    //cnt��¼���ֳɹ��Ĵ���
    reg [3:0] cnt = 0;
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n) cnt <= 0;
	else if (valid_insert && valid_in && ready_in && ready_insert && cnt == 0)     
	      cnt <= cnt + 1;
    end
    
    reg [DATA_WD-1:0] data_out_temp;//��¼��ʵ���
    genvar i;
    generate for(i = 5'd0; i<DATA_BYTE_WD; i=i+1)
    begin
    always @(posedge clk or negedge rst_n)
        begin
            if(valid_insert && valid_in && ready_in && ready_insert)
                begin
                if(i<insert_temp)
                    data_out_temp[i] = header_insert[i+insert_temp];
                else
                    data_out_temp[i] = data_in[i+insert_temp];
                end
        end
    end
    endgenerate
    
    initial
    begin
        header_insert = $random(seed);
        if(cnt == 500)
            $finish;
    end
    
    reg [7:0] err_cnt = 8'd0;
    always @(posedge clk or negedge rst_n) begin
        if (valid_insert && valid_in && ready_in && ready_insert) 
        begin
            if (data_out_temp != data_out) begin
                err_cnt = err_cnt + 1'b1 ;
            end
        end
    end
    always @(posedge clk or negedge rst_n) 
    begin
            if (!err_cnt) 
            begin
                $display("-------------------------------------");
                $display("Data process is OK!!!");
                $display("-------------------------------------");
            end
            else 
            begin
                $display("-------------------------------------");
                $display("Error occurs in data process!!!");
                $display("-------------------------------------");
            end      
    end
    //simulation finish
endmodule
