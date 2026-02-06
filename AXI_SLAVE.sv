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

typedef enum logic{
    START,
    OK
}phase_t;

logic ready;
logic count;
logic [31:0]data_buffer_1;
logic [31:0]addr_buffr;
state_t state;
phase_t phase;
logic AWalrt;
logic Walrt;


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
                end
            end
            DECODE:begin
                BRESP <= 2'b00;
                case(addr_buffr)
                    Tx_address: begin
                        Tx_data_out <= data_buffer_1; // this pin should be connected with Tx_din pin of Tx_FIFO ans: yes
                        BRESP <= 2'b00;
                        BVALID <= 1;
                        if(BVALID & BREADY) begin
                            state <= EXECUTE;
                        end
                    end

                    SS_address: begin
                        SS_data_out <= data_buffer_1; //   this pin should be connected with Tx_din pin of Tx_FIFO ans: yes
                        BRESP <= 2'b00;
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


/*
this block cheks AWVALID and FREADY_full , WDATA and FREADY_full constantly and makes ready 1 such that when 
ready is 1 we can be sure that handshkae happened
*/
always_ff@(posedge ACLK)begin : handshake_block
    if(!ARESETN)begin
        phase <= START;
        ready <= 0;
        AWalrt <= 0;
        Walrt <= 0;
    end else begin
        case(phase)
            START:begin
                if(AWVALID & AWREADY) begin
                    AWalrt <= 1; // handshake for address
                    addr_buffr <= AWADDR;
                 end
                if(WVALID & WREADY)begin
                    Walrt <= 1;    // handshake for data
                    data_buffer_1 <= WDATA;
                end
                if(AWalrt & Walrt) begin   // This ensure both handshake 
                ready <= 1; 
                phase <= OK;
                end
            end

            OK:begin
                ready <= 0;
                AWalrt <= 0;
                Walrt <= 0;
                if(BVALID & BREADY) begin // this make sure that unless and untill transaction is completed do not move onto new state where we accept new data 
                    phase <= START; 
                end
            end


        endcase

    end

end

always_comb begin : ready_block
    if(FREADY_full && (phase == START) && (state == IDEAL) )begin
        AWREADY = 1;
        WREADY = 1;
    end else begin
        AWREADY = 0;
        WREADY = 0;
    end

end


endmodule