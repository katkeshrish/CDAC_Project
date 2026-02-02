module FIFO_Counter(
    output logic [31:0]data_out,
    output logic empty,
    output logic full,
    input logic [31:0]data,
    input logic wr_en,
    input logic rd_en,
    input logic clk,
    input logic rst_n
);

logic [31:0]mem[15:0];
logic [4:0]wr_ptr;
logic [4:0]rd_ptr;
logic [4:0]counter;

always_ff@(posedge clk) begin : main_block
    if(!rst_n) begin
        // empty <= 1;
        // full <= 0;
        data_out <= 0;
        wr_ptr <= 0;
        rd_ptr <= 0;
        counter <= 0;
    end else begin


        //write logic
        if(wr_en & !full ) begin
            if(wr_ptr+1 == 5'd16) begin
                mem[wr_ptr] <= data;
                wr_ptr <= 0;
                counter <= counter + 1;
            end else begin
                mem[wr_ptr] <= data;
                counter <= counter + 1;
                wr_ptr <= wr_ptr + 1;
                // empty <= 0;
            end
        end

        //read logic 
        if(rd_en & !empty) begin
            if(rd_ptr+1 == 5'd16) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= 0;
                counter <= counter - 1; 
            end else begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                counter <= counter - 1; 
                // full <= 0;
            end
        end

        if(wr_en & !full & rd_en & !empty) begin
            counter <= counter;
        end
    
    
    end

end

always_comb begin :Full_empty_block
    case(counter)
    5'd16: 
    begin
        full = 1;
        empty = 0;
    end

    5'd0:
    begin
        empty = 1;
        full = 0;
    end

    default:
    begin
        full = 0;
        empty = 0;
    end

    endcase

   
end


endmodule






