module FIFO_MANAGER(
    input logic Tx_full,
    input logic SS_full,
    input logic Tx_empty,
    input logic SS_empty,
    output logic FREADY_full,
    output logic FREADY_empty
);

always_comb begin : Full_empty_block
    if(Tx_full | SS_full)begin
        FREADY_full = 0;
    end else begin
        FREADY_full = 1;
    end

    if(Tx_empty | SS_empty) begin
        FREADY_empty = 0;
    end else begin
        FREADY_empty = 1;
    end

end


endmodule