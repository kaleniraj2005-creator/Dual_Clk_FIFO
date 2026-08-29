module Async_fifo (
  input  logic       wr_clk,
  input  logic       wr_rst,
  input  logic       wr_en,
  input  logic [7:0] wr_data,
  output logic       full,

  input  logic       rd_clk,
  input  logic       rd_rst,
  input  logic       rd_en,
  output logic [7:0] rd_data,
  output logic       empty
);

  logic [4:0] wr_ptr_bin;
  logic [4:0] rd_ptr_bin;

  logic [4:0] wr_ptr_gray;
  logic [4:0] rd_ptr_gray;

  logic [4:0] wr_ptr_bin_next;
  logic [4:0] rd_ptr_bin_next;

  logic [4:0] wr_ptr_gray_next;
  logic [4:0] rd_ptr_gray_next;

  logic [4:0] rd_ptr_gray_sync;
  logic [4:0] wr_ptr_gray_sync;

  logic [7:0] mem [0:15];

  //Write pointer
  always_ff @(posedge wr_clk or posedge wr_rst) begin
    if (wr_rst)
      wr_ptr_bin <= 5'b00000;
    else
      wr_ptr_bin <= wr_ptr_bin_next;
    end
  //Read pointer
  always_ff @(posedge rd_clk or posedge rd_rst) begin
    if (rd_rst)
      rd_ptr_bin <= 5'b00000;
    else
      rd_ptr_bin <= rd_ptr_bin_next;
  end
  
  //next write pointer
  always @(*) begin
    wr_ptr_bin_next = wr_ptr_bin;
    if (wr_en && !full)
      wr_ptr_bin_next = wr_ptr_bin + 1'b1;
  end

  //next read pointer
  always @(*) begin
    rd_ptr_bin_next = rd_ptr_bin;
    if (rd_en && !empty)
      rd_ptr_bin_next = rd_ptr_bin + 1'b1;
  end

  always @(*) begin
    wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);
  end

  always_comb begin
    rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);
  end

  always_comb begin
    wr_ptr_gray_next = wr_ptr_bin_next ^ (wr_ptr_bin_next >> 1);
  end

  always_comb begin
    rd_ptr_gray_next = rd_ptr_bin_next ^ (rd_ptr_bin_next >> 1);
  end


  //write pointer synchronizer, write to read domain
  logic [4:0] wr_sync_ff1;

  always_ff @(posedge rd_clk or posedge rd_rst) begin
    if (rd_rst) begin
      wr_sync_ff1 <= 5'b00000;
      wr_ptr_gray_sync <= 5'b00000;
    end
    else begin
      wr_sync_ff1 <= wr_ptr_gray;
      wr_ptr_gray_sync <= wr_sync_ff1;
    end
  end

  //Read pointer synchronizer, read to write domain

  logic [4:0] rd_sync_ff1;
  always_ff @(posedge wr_clk or posedge wr_rst) begin
    if (wr_rst) begin
      rd_sync_ff1 <= 5'b00000;
      rd_ptr_gray_sync <= 5'b00000;
    end
    else begin
      rd_sync_ff1 <= rd_ptr_gray;
      rd_ptr_gray_sync <= rd_sync_ff1;
    end
  end


  //Empty
  always_ff @(posedge rd_clk or posedge rd_rst) begin
    if (rd_rst)
      empty <= 1'b1;
    else
      empty <= (rd_ptr_gray_next == wr_ptr_gray_sync);
  end

  //Full
  always_ff @(posedge wr_clk or posedge wr_rst) begin
    if (wr_rst)
      full <= 1'b0;
    else
      full <= (wr_ptr_gray_next == {~rd_ptr_gray_sync[4:3],rd_ptr_gray_sync[2:0]});  
  end

  //Write data from fifo
  always_ff @(posedge wr_clk) begin
    if (wr_en && !full)
      mem[wr_ptr_bin[3:0]] <= wr_data;
  end

  // Read data from fifo
  always_ff @(posedge rd_clk) begin
    if (rd_en && !empty)
      rd_data <= mem[rd_ptr_bin[3:0]];
  end
endmodule