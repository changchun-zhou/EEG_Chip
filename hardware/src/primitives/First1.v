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
    Addr = 'd0;
    for(i=LEN-1; i>=0; i=i-1) begin
        if(Array[i]) begin
            Addr = i;
        end
    end
end

endmodule