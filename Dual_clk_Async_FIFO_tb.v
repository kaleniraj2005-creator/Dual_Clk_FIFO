module Async_fifo_tb;
  logic       wr_clk;
  logic       wr_rst;
  logic       wr_en;
  logic [7:0] wr_data;
  logic       full;
  logic       rd_clk;
  logic       rd_rst;
  logic       rd_en;
  logic [7:0] rd_data;
  logic       empty;
  
  Async_fifo uut(
    .wr_clk(wr_clk),
    .wr_rst(wr_rst),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .full(full),
    .rd_clk(rd_clk),
    .rd_rst(rd_rst),
    .rd_en(rd_en),
    .rd_data(rd_data),
    .empty(empty)
  );
  initial begin
    wr_clk = 0;
    forever #5 wr_clk = ~wr_clk;
  end
  initial begin
    rd_clk = 0;
    forever #7 rd_clk = rd_clk;
  end
  initial begin
    wr_en = 0;
    wr_rst = 1;
    wr_data = 8'b00000000;
    
    rd_en = 0;
    rd_rst = 1;
    
    #10;
    wr_rst = 0;
    rd_rst = 0;
    
    @(posedge wr_clk);
    wr_en = 1;
    wr_data = 8'hC2;
    
    @(posedge wr_clk);
    wr_data = 8'h0A;
    
    @(posedge wr_clk);
    wr_data = 8'hB6;
    
    #10;
    wr_en = 0;
    rd_en = 1;
    
    @(posedge rd_clk);
    
    @(posedge rd_clk);
    
    @(posedge rd_clk);
    
    #10 rd_en = 0;
    wr_en = 1;
    
    @(posedge wr_clk);
    wr_data = 8'hF0;
    
    @(posedge wr_clk);
    wr_data = 8'hE1;
    
    @(posedge wr_clk);
    wr_data = 8'hD2;
    
    @(posedge wr_clk);
    wr_data = 8'hC3;
    
    @(posedge wr_clk);
    wr_data = 8'hB4;
    
    @(posedge wr_clk);
    wr_data = 8'hA5;
    
    @(posedge wr_clk);
    wr_data = 8'h96;
    
    @(posedge wr_clk);
    wr_data = 8'h87;
    
    @(posedge wr_clk);
    wr_data = 8'h78;
    
    @(posedge wr_clk);
    wr_data = 8'h69;
    
    @(posedge wr_clk);
    wr_data = 8'h5A;
    
    @(posedge wr_clk);
    wr_data = 8'h4B;
    
    @(posedge wr_clk);
    wr_data = 8'h3C;
    
    @(posedge wr_clk);
    wr_data = 8'h2D;
    
    @(posedge wr_clk);
    wr_data = 8'h1E;
    
    @(posedge wr_clk);
    wr_data = 8'h0F;
    
    @(posedge wr_clk);
    wr_data = 8'h05;
    
    #20 $finish;
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,Async_fifo_tb);
  end
endmodule