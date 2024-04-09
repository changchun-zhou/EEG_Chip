module CPM_MISO_FIFO
#(  // Parameters
    parameter   DATA_WIDTH          = 64,
    parameter   ADDR_WIDTH          = 4,
    parameter   DATA_NUMAW          = 3,
    parameter   DATA_MAX_N          = (1 << DATA_NUMAW),
    parameter   RAM_DEPTH           = (1 << ADDR_WIDTH),
    parameter   REG_OUT             = "true"
)(  // Ports
    input  wire                                  clk,
    input  wire                                  rst_n,
    input  wire                                  Reset,
    input  wire                                  push,
    input  wire                                  pop,
    input  wire [ DATA_MAX_N*DATA_WIDTH -1 : 0 ] data_in,
    input  wire [ DATA_NUMAW            -1 : 0 ] data_in_num,//-1
    output reg  [ DATA_WIDTH            -1 : 0 ] data_out,
    output reg                                   empty,
    output reg                                   full,//failed to fit data_in_num
    output reg  [ ADDR_WIDTH               : 0 ] fifo_count, //must use to fit data_in_num
    output reg  [ ADDR_WIDTH               : 0 ] fifo_count_empty
);

// Port Declarations
// ******************************************************************
// Internal variables
// ******************************************************************
reg  full_mi;
wire [DATA_MAX_N-1:0][DATA_WIDTH-1:0] data_in_sep = data_in;
reg  [ADDR_WIDTH-1:0] wr_pointer;             //Write Pointer
reg  [ADDR_WIDTH-1:0] rd_pointer;             //Read Pointer
reg  [DATA_WIDTH-1:0] mem[0:RAM_DEPTH-1];     //Memory/*synthesis ramstyle = "MLAB" */
// ******************************************************************
// INSTANTIATIONS
// ******************************************************************
always @ ( * )
begin
      empty   = (fifo_count == 0);
      full    = (fifo_count == RAM_DEPTH);
      full_mi = fifo_count_empty<data_in_num+1;
end

always @ (posedge clk or negedge rst_n)begin
      if (!rst_n)
          fifo_count <= 0;
      else if( Reset)
          fifo_count <= 0;
      else if (push && (!pop||pop&&empty) && !full_mi)
          fifo_count <= fifo_count + data_in_num +1;
      else if (pop && (!push||push&&full_mi) && !empty)
          fifo_count <= fifo_count - 1;
      else if (push && pop && !empty && !full_mi )
          fifo_count <= fifo_count + data_in_num;
end

always @ (posedge clk or negedge rst_n)begin
    if (!rst_n)
        fifo_count_empty <= RAM_DEPTH;
    else if( Reset)
        fifo_count_empty <= RAM_DEPTH;
    else if (push && (!pop||pop&&empty) && !full_mi)
        fifo_count_empty <= fifo_count_empty - data_in_num-1;
    else if (pop && (!push||push&&full_mi) && !empty)
        fifo_count_empty <= fifo_count_empty + 1;
    else if (push && pop && !empty && !full_mi )
        fifo_count_empty <= fifo_count_empty - data_in_num;
end

always @ (posedge clk or negedge rst_n)begin
    if (!rst_n) begin
        wr_pointer <= 0;
    end else if( Reset )begin
        wr_pointer <= 0;
    end else if (push && !full_mi) begin
        wr_pointer <= wr_pointer + data_in_num+1;
    end
end

always @ (posedge clk or negedge rst_n)begin
    if (!rst_n) begin
        rd_pointer <= 0;
    end else if( Reset )begin
        rd_pointer <= 0;
    end else if (pop && !empty) begin
        rd_pointer <= rd_pointer + 1;
    end
end

integer i;
always @ (posedge clk or negedge rst_n)begin
    if( !rst_n) begin
        for(i=0; i<RAM_DEPTH; i=i+1)begin
            mem[i] <= 0;
        end
    end else if (push && !full_mi) begin
        for(i=0; i<DATA_MAX_N; i=i+1)begin
            if( i<=data_in_num )
                mem[wr_pointer+i] <= data_in_sep[i];
        end
    end
end

generate
    if( REG_OUT=="true" )begin
        always @ (posedge clk or negedge rst_n)begin
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
