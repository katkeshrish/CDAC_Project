module Async_Tx_FIFO #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4  
)(
    input  logic [DATA_WIDTH-1:0] data_in,
    input  logic wr_en,
    input  logic rd_en,
    input  logic ACLK,   // AXI Clock
    input  logic SCLK,   // SPI Clock
    input  logic rst_n,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic empty,
    output logic full
);

    // Memory Array
    logic [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Binary and Gray Pointers (Extra bit for Full/Empty detection)
    logic [ADDR_WIDTH:0] wr_ptr_bin, rd_ptr_bin;
    logic [ADDR_WIDTH:0] wr_ptr_gry, rd_ptr_gry;

    // Synchronization Registers
    logic [ADDR_WIDTH:0] wr_ptr_sync1, wr_ptr_sync2;
    logic [ADDR_WIDTH:0] rd_ptr_sync1, rd_ptr_sync2;

    // --- WRITE DOMAIN (ACLK) ---
    always_ff @(posedge ACLK or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin <= 0;
            wr_ptr_gry <= 0;
        end else if (wr_en && !full) begin
            wr_ptr_bin <= wr_ptr_bin + 1;
            wr_ptr_gry <= ((wr_ptr_bin + 1) >> 1) ^ (wr_ptr_bin + 1);
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= data_in;
        end
    end

    // --- READ DOMAIN (SCLK) ---
    always_ff @(posedge SCLK or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin <= 0;
            rd_ptr_gry <= 0;
            data_out   <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gry <= ((rd_ptr_bin + 1) >> 1) ^ (rd_ptr_bin + 1);
            data_out   <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
        end
    end

    // --- 2-FF SYNCHRONIZER: Write to Read (SCLK Domain) ---
    always_ff @(posedge SCLK or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_sync1 <= 0;
            wr_ptr_sync2 <= 0;
        end else begin
            wr_ptr_sync1 <= wr_ptr_gry;
            wr_ptr_sync2 <= wr_ptr_sync1;
        end
    end

    // --- 2-FF SYNCHRONIZER: Read to Write (ACLK Domain) ---
    always_ff @(posedge ACLK or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_sync1 <= 0;
            rd_ptr_sync2 <= 0;
        end else begin
            rd_ptr_sync1 <= rd_ptr_gry;
            rd_ptr_sync2 <= rd_ptr_sync1;
        end
    end

    // --- FLAG LOGIC (Combinational) ---
    // Empty: Gray pointers are identical
    assign empty = (wr_ptr_sync2 == rd_ptr_gry);

    // Full: MSB and MSB-1 are inverted, remaining bits same
    assign full  = (wr_ptr_gry == {~rd_ptr_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_sync2[ADDR_WIDTH-2:0]});

endmodule