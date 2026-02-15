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


always_ff@(posedge ACLK)begin : AXI_SLAVE_FSM
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
                /*
                    based on the address we recieved in handshake_block FSM we will store the data either into Async_Tx_FIFO
                    or Async_SS_FIFO
                */
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
                        if(BVALID & BREADY)begin // we make this handshake so that it tells master to check the BERESP line is that response
                            state <= EXECUTE;
                        end
                    end

                    endcase
            end

            EXECUTE:begin
                BVALID <= 0;
                wr_en <= 1;
                state <= IDEAL;
                BRESP <= 2'b00; // after above handshake we make BERESP so that master can check the status of the transaction
            end

        endcase
             
    end


end


/*
this block cheks AWVALID and AWREADY , WDATA and WREADY constantly and makes ready 1 such that when 
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
                /*
                    unless untill we have both Address and Data we shall not write into FIFO such as it may happen
                    Address may come first and then after 10 clock cycle Data comes but till the data comes we must hold our
                    system/FSM and when data comes and handshake happens for we make sure that both handshake has happened and only
                    then we must proceed 
                    so even if the wrong address comes handshake must happen , if the addres is write or wrong that shall be check
                    by AXI_SLAVE_FSM
                */
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
/*
so this combinational block constantly cheks for the FIFO not being full and both FSM are in the 1st state and then only
it makes these both signal as 1 otherwise it keeps them as 0. it ensures that handshake only happen at the start of the transaction
because FREADY_full will most of the time be 1 so if we only checks this condition then handshake_FSM may accept new address and 
it will overwrite current address or data so we ensuer that when FREADY_full is 1 out Both FSM also need to be in 1st state and this will
happen at start of the transaction 
*/
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