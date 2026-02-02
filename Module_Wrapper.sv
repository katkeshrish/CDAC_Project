module Module_Wrapper (
    input logic ACLK,
    input logic ARESETN,
    
    // AXI4-Lite Interface
    input  logic [31:0] AWADDR,
    input  logic AWVALID,
    output logic AWREADY,
    input  logic [31:0] WDATA,
    input  logic WVALID,
    output logic WREADY,
    output logic [1:0] BRESP,
    output logic BVALID,
    input  logic BREADY,

    // SPI Interface
    output logic [1:0] SS,
    output logic MOSI,
    output logic SCLK,
    input  logic MISO
);

    // 1. Internal Wires Declaration
    logic sclk_int;
    logic fready_full, fready_empty;
    logic wr_en, rd_en;
    logic [31:0] tx_data_bus, ss_data_bus;
    logic [31:0] fifo_tx_out, fifo_ss_out;
    logic go, dready, sresp;
    logic tx_full, tx_empty, ss_full, ss_empty;

    // 2. Instantiate FDIVIDER
    FDIVIDER fdiv_inst (
        .ACLK(ACLK),
        .RESTN(ARESETN),
        .SCLK(sclk_int)
    );

    // 3. Instantiate AXI_SLAVE
    AXI_SLAVE axi_inst (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        .AWADDR(AWADDR), .AWVALID(AWVALID), .AWREADY(AWREADY),
        .WDATA(WDATA), .WVALID(WVALID), .WREADY(WREADY),
        .BRESP(BRESP), .BVALID(BVALID), .BREADY(BREADY),
        .FREADY_full(fready_full),
        .wr_en(wr_en),
        .Tx_data_out(tx_data_bus),
        .SS_data_out(ss_data_bus)
    );

    // 4. Instantiate FIFOs (Tx and SS)
    FIFO_Counter tx_fifo_inst (
        .clk(ACLK), .rst_n(ARESETN),
        .data(tx_data_bus), .wr_en(wr_en), .rd_en(rd_en),
        .data_out(fifo_tx_out), .full(tx_full), .empty(tx_empty)
    );
    
    FIFO_Counter ss_fifo_inst (
        .clk(ACLK), .rst_n(ARESETN),
        .data(ss_data_bus), .wr_en(wr_en), .rd_en(rd_en),
        .data_out(fifo_ss_out), .full(ss_full), .empty(ss_empty)
    );

    // 5. Instantiate FIFO_MANAGER
    FIFO_MANAGER fifo_mgmt_inst (
        .Tx_full(tx_full), .SS_full(ss_full),
        .Tx_empty(tx_empty), .SS_empty(ss_empty),
        .FREADY_full(fready_full), .FREADY_empty(fready_empty)
    );

    // 6. Instantiate DATA_BUFFER
    DATA_BUFFER dbuff_inst (
        .din_1(fifo_tx_out), .din_2(fifo_ss_out),
        .go(go), .SCLK(sclk_int), .ARESETN(ARESETN),
        .SRESP(sresp), .DREADY(dready),
        .dout(data_to_master) // Internal 34-bit bus
    );

    // 7. Instantiate SPI_MASTER
    SPI_MASTER master_inst (
        .FSCLK(sclk_int), .ARESETN(ARESETN),
        .FREADY_empty(fready_empty),
        .DREADY(dready), .din(data_to_master),
        .go(go), .SRESP(sresp), .rd_en(rd_en),
        .SS(SS), .MOSI(MOSI), .SCLK(SCLK), .MISO(MISO)
    );

endmodule