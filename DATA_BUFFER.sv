module DATA_BUFFER(
    // input from Tx_FIFO
    input logic[31:0] din_1,

    //input from SS_FIFO
    input logic[31:0]din_2,

    //input "go" from SPI master
    input logic go,

    //input clk and reset now this clk and reset is from AXI but if we decide we can add SPI clock later and this block works on SPI clock
    input logic SCLK,
    input logic ARESETN,

    //input from SPI master that tells i received the data
    input logic SRESP,

    //output DREADY for SPI MASTER
    output logic DREADY,

    //output to SPI master 
    output logic [33:0]dout
);


typedef enum logic[2:0]{
    IDEAL,
    WAIT_FIFO,
    FETCH,
    CONCATENATE,
    VALIDATE
} state_t;

logic [31:0] SS_buffer_1;
logic [1:0] SS_buffer_2;
state_t state;

always_ff(posedge SCLK) begin : data_fetch_block
    if(!ARESETN)begin
        state <= IDEAL;
        DREADY <= 0;
    end else begin
        case(state)
            IDEAL:begin
                DREADY <= 0;
                if(go) begin
                    state <= WAIT_FIFO;
                end
            end

            WAIT_FIFO: begin
                state <= FETCH;
            end

            FETCH:begin
                SS_buffer_1 <= din_1;
                SS_buffer_2 <= din_2[1:0];
                state <= CONCATENATE;
            end

            CONCATENATE:begin
                dout <= {SS_buffer_2,SS_buffer_1};
                state <= VALIDATE;
                DREADY <= 1;
            end

            VALIDATE:begin
                if(DREADY & SRESP)begin
                    state <= IDEAL;
                end
                
            end


        endcase
    end

end


endmodule