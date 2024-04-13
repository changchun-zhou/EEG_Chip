module First1 #(
    parameter LEN       = 32,
    parameter ADDR_WIDTH= $clog2(LEN)
)(
    input       [LEN          -1 : 0] Array,
    output reg  [ADDR_WIDTH   -1 : 0] Addr
);

integer i;
reg     flag;

always@(*) begin
    flag = 'd0;
    Addr = 'd0;
    for(i=0; i<LEN; i=i+1) begin
        if(Array[i] & !flag) begin
            Addr = i;
            flag = 1'b1;
        end
    end
end

endmodule