module CPM_FIFO_EX
#(  // Parameters
    parameter   DATA_WIDTH          = 64,
    parameter   ADDR_WIDTH          = 4,
    parameter   RAM_DEPTH           = (1 << ADDR_WIDTH),
    parameter   REG_OUT             = 0
)(  // Ports
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         Reset,
    input  wire                         push,
    input  wire                         pop,
    input  wire [ DATA_WIDTH -1 : 0 ]   data_in,
    output reg  [ DATA_WIDTH -1 : 0 ]   data_out,
    output reg                          empty,
    output reg                          full,
    output reg  [ ADDR_WIDTH    : 0 ]   fifo_count,
    output reg  [ ADDR_WIDTH    : 0 ]   fifo_count_empty
);

// Port Declarations
// ******************************************************************
// Internal variables
// ******************************************************************
reg     [ADDR_WIDTH-1:0]        wr_pointer;             //Write Pointer
reg     [ADDR_WIDTH-1:0]        rd_pointer;             //Read Pointer
reg     [DATA_WIDTH-1:0]        mem[0:RAM_DEPTH-1];     //Memory/*synthesis ramstyle = "MLAB" */
// ******************************************************************
// INSTANTIATIONS
// ******************************************************************
always @ (fifo_count)
begin : FIFO_STATUS
  empty   = (fifo_count == 0);
  full    = (fifo_count == RAM_DEPTH);
end

always @ (posedge clk or negedge rst_n)
begin : FIFO_COUNTER
  if (!rst_n) begin
      fifo_count <= 0;
  end else if( Reset) begin
      fifo_count <= 0;
  end else if (push && (!pop||pop&&empty) && !full)
    fifo_count <= fifo_count + 1;
  else if (pop && (!push||push&&full) && !empty)
    fifo_count <= fifo_count - 1;
end

always @ (posedge clk or negedge rst_n)
begin : FIFO_COUNTER_EMPTY
    if (!rst_n) begin
        fifo_count_empty <= RAM_DEPTH;
    end else if( Reset) begin
        fifo_count_empty <= RAM_DEPTH;
    end else if (push && (!pop||pop&&empty) && !full)
        fifo_count_empty <= fifo_count_empty - 1;
    else if (pop && (!push||push&&full) && !empty)
        fifo_count_empty <= fifo_count_empty + 1;
end

always @ (posedge clk or negedge rst_n)
begin : WRITE_PTR
  if (!rst_n) begin
    wr_pointer <= 0;
  end else if( Reset )begin
    wr_pointer <= 0;
  end else if (push && !full) begin
    wr_pointer <= wr_pointer + 1;
  end
end

always @ (posedge clk or negedge rst_n)
begin : READ_PTR
  if (!rst_n) begin
    rd_pointer <= 0;
  end else if( Reset )begin
    rd_pointer <= 0;
  end else if (pop && !empty) begin
    rd_pointer <= rd_pointer + 1;
  end
end

integer i;
always @ (posedge clk or negedge rst_n) begin :WRITE
  if( !rst_n) begin
    for(i=0; i<RAM_DEPTH; i=i+1)begin
        mem[i] <= 0;
    end
  end else if (push && !full) begin
    mem[wr_pointer] <= data_in;
  end
end

generate
    if( REG_OUT==1 )begin
        always @ (posedge clk or negedge rst_n)
        begin : READ
          if (!rst_n) begin
            data_out <= 0;
          end else if (pop && !empty) begin
            data_out <= mem[rd_pointer];
          end else begin
            data_out <= data_out;
          end
        end
    end
    else begin
        always @ ( * )begin
            data_out = mem[rd_pointer];
        end
    end
endgenerate

endmodule
