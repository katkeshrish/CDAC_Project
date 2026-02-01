module AXI_SLAVE(
    input logic ACLK,
    input logic ARESETN,

    //write address(AW)
    input logic [31:0]AWADDR,
    input logic AWVALID,
    output logic AWREADY,

    //Write Data(W)
    input logic [31:0]WDATA,
    input logic WVALID,
    input logic WSTRB,
    output logic WREADY,

    // write response (B)
    output logic[1:0]BRESP,
    output logic BVALID,
    input logic BREADY,

    //handshake signal 
    input logic FREADY_full,
    output logic wr_en,

    //FIFO data signals
    output logic[31:0]Tx_data_out,
    output logic[31:0]SS_data_out
    
);

typedef enum logic[1:0] { 
    OKAY,
    SLERROR
} resp_t;

 typedef enum logic[31:0]{
    Tx_address = 32'h0,
    SS_address = 32'h2

 } addr_t;

 typedef enum logic[1:0]{
    IDEAL,
    DECODE,
    EXECUTE
 } state_t;

logic ready;
logic count;
logic [31:0]data_buffer_1;
logic [31:0]addr_buffr;
state_t state;


always_ff@(posedge ACLK)begin : AXI_SLAVE
    if(!ARESETN)begin
        wr_en <= 0;
        state <= IDEAL;

    end else begin
        wr_en <= 0;
        case(state)
            IDEAL: begin
                BRESP <= 2'b00;
                if(ready) begin
                    state <= DECODE;
                    data_buffer_1 <= WDATA;
                    addr_buffr <= AWADDR;
                end
            end
            DECODE:begin
                BRESP <= 2'b00;
                case(addr_buffr)
                    Tx_address: begin
                        Tx_data_out <= data_buffer_1; // this pin should be connected with Tx_din pin of Tx_FIFO ans: yes
                        BRESP <= 2'b00;
                        // wr_en <= 1;
                        BVALID <= 1;
                        if(BVALID & BREADY) begin
                            state <= EXECUTE;
                        end
                    end

                    SS_address: begin
                        SS_data_out <= data_buffer_1; //   this pin should be connected with Tx_din pin of Tx_FIFO ans: yes
                        BRESP <= 2'b00;
                        // wr_en <= 1;
                        BVALID <= 1;
                        if(BVALID & BREADY) begin
                            state <= EXECUTE;
                        end
                    end

                    default: begin
                        BRESP <= 2'b10;
                        BVALID <= 1;
                        if(BVALID & BREADY)begin
                            state <= EXECUTE;
                        end
                    end

                    endcase
            end

            EXECUTE:begin
                BVALID <= 0;
                wr_en <= 1;
                state <= IDEAL;
                BRESP <= 2'b00;
            end

        endcase
             
    end


end


// this block cheks AWVALID and FREADY_full , WDATA and FREADY_full constantly and makes ready 1 such that when ready is 1 we can be sure that handshkae happened
always_comb begin : handshake_block
    if(AWVALID & AWREADY & WVALID & WREADY)begin
        ready = 1; // this ensure handshake
    end 
    else begin
        ready = 0;
    end

end

always_comb begin : ready_block
    if(FREADY_full)begin
        AWREADY = 1;
        WREADY = 1;
    end else begin
        AWREADY = 0;
        WREADY = 0;
    end

end


endmodule