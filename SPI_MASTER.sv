module SPI_MASTER(
    //input from Fdivider clk
    input logic FSCLK,
    input logic ARESETN,

    //input from FIFO_MANAGER
    input logic FREADY_empty,

    //signals to DATA_BUFFER
    input logic DREADY,
    input logic [33:0] din,
    output logic go,
    output logic SRESP,

    // rd_en signal to both FIFO
    output logic rd_en

    //Standard SPI signals
    output logic[1:0]SS,
    output logic MOSI,
    output logic SCLK,
    input logic MISO


);

typedef enum logic[2:0]{
    IDEAL,
    WAIT_FIFO,
    FETCH,
    START,
    DONE,
    VALIDATE

} state_t;

logic [5:0]count;
logic [31:0] data_buffer_3;
logic [1:0] data_buffer_4;
state_t state;

assign SCLK = (state == START) ? FSCLK : 0;

always_ff@(posedge FSCLK) begin : main_FSM_block
    if(!ARESETN)begin
        state <= IDEAL;
        count <= 0;
        rd_en <= 0;
        go <= 0;
        SRESP <= 0;
    end else begin
        case(state)
            IDEAL:begin
                go <= 0;
                if(FREADY_empty)begin
                    go <= 1;
                    rd_en <= 1;
                    state <= WAIT_FIFO;
                    count <= 0;
                end
            end

            WAIT_FIFO:begin
                rd_en <= 0;
                go <= 0;
                state <=FETCH;
            end

            FETCH:begin
                data_buffer_3 <= din[31:0];
                data_buffer_4 <= din[33:32];
                SS <= din[33:32];
                state <= START;
            end

            START:begin
                if(count == 6'd32) begin
                    state <= DONE;
                end else begin
                    if(DREADY) begin
                        MOSI <= data_buffer_3[31];
                        data_buffer_3 <= {data_buffer_3[30:0],1'b0};
                        count <= count +1;
                    end
                end
            end

            DONE: begin
                SRESP <= 1;
                state <= VALIDATE;
            end

            VALIDATE:begin
                SRESP <= 0;
                state <= IDEAL;
            end
        endcase
    end

end





endmodule