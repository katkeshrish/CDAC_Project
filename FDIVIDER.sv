module FDIVIDER(
    input  logic ACLK,
    input  logic RESTN,
    output logic  SCLK
);
logic [3:0]count;

always_ff@(posedge ACLK)begin
    if(!RESTN)begin
        count <= 0;
        SCLK <= 0;
    end else begin
        if(count == 4'd4)begin
            count <= 0;
            SCLK <= ~SCLK;
        end else begin
            count <= count +1;
        end
    end

end

endmodule