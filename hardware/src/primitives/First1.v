module First1 #(
    parameter LEN,
    parameter ADDR_WIDTH = $clog2(LEN)
)(
    input [LEN          -1 : 0] Array,
    output[ADDR_WIDTH   -1 : 0] Addr
)

integer i;
reg     flag;

always@(*) begin
    flag = 1'b0;
    for(i=0; i<LEN; i=i+1) begin
        if(Array[i] & !flag) begin
            Addr = i;
            flag = 1'b1;
        end
    end
end

endmodule