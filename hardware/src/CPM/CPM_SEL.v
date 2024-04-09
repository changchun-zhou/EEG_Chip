//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description :
//========================================================
module CPM_SEL #(
    parameter DW = 8,
    parameter AW = $clog2(DW)
) (
    input  [DW -1:0] SEL,
    output [AW -1:0] IDX
);

integer i;

reg [AW -1:0] idx;
assign IDX = idx;

always @ ( * )begin
    idx = 0;
    for( i = 0; i < DW; i = i + 1 )begin
        if( SEL[i]==1 )
            idx = i;
    end
end
  
endmodule
