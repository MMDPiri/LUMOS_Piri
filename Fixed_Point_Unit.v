`include "Defines.vh"

module Fixed_Point_Unit 
#(
    parameter WIDTH = 32,
    parameter FBITS = 10
)
(
    input wire clk,
    input wire reset,
    
    input wire [WIDTH - 1 : 0] operand_1,
    input wire [WIDTH - 1 : 0] operand_2,
    
    input wire [ 1 : 0] operation,

    output reg [WIDTH - 1 : 0] result,
    output reg ready
);

    always @(*)
    begin
        case (operation)
            `FPU_ADD    : begin result <= operand_1 + operand_2; ready <= 1; end
            `FPU_SUB    : begin result <= operand_1 - operand_2; ready <= 1; end
            `FPU_MUL    : begin result <= product[WIDTH + FBITS - 1 : FBITS]; ready <= product_ready; end
            `FPU_SQRT   : begin result <= root; ready <= root_ready; end
            default     : begin result <= 'bz; ready <= 0; end
        endcase
    end

    always @(posedge reset)
    begin
        if (reset)  ready = 0;
        else        ready = 'bz;
    end
    // ------------------- //
    // Square Root Circuit //
    // ------------------- //
    reg [WIDTH - 1 : 0] root;
    reg root_ready;

    reg [1 : 0] current_square_phase;
    reg [1 : 0] next_square_phase;

    always @(posedge clk) 
    begin
        if (operation == `FPU_SQRT) current_square_phase <= next_square_phase;
        else                        
        begin
            current_square_phase <= 2'b00;
            root_ready <= 0;
        end
    end 

    always @(*) 
    begin
        next_square_phase <= 'bz;
        case (current_square_phase)
            2'b00 : begin sqrt_function_begin <= 0; next_square_phase <= 2'b01; end
            2'b01 : begin sqrt_function_begin <= 1; next_square_phase <= 2'b10; end
            2'b10 : begin sqrt_function_begin <= 0; next_square_phase <= 2'b10; end
        endcase    
    end
    reg sqrt_function_begin;
    reg sqrt_function_busy;
    
    reg [WIDTH - 1 : 0] x, xnew;              
    reg [WIDTH - 1 : 0] q, qnew;              
    reg [WIDTH + 1 : 0] ac, acnew;            
    reg [WIDTH + 1 : 0] test_result;               

    reg valid;

    localparam ITER = (WIDTH + FBITS) >> 1;     
    reg [4 : 0] i = 0;                              

    always @(*)
    begin
        test_result = ac - {q, 2'b01};

        if (test_result[WIDTH + 1] == 0) 
        begin
            {acnew, xnew} = {test_result[WIDTH - 1 : 0], x, 2'b0};
            qnew = {q[WIDTH - 2 : 0], 1'b1};
        end 
        else 
        begin
            {acnew, xnew} = {ac[WIDTH - 1 : 0], x, 2'b0};
            qnew = q << 1;
        end
    end
    
    always @(posedge clk) 
    begin
        if (sqrt_function_begin)
        begin
            sqrt_busy <= 1;
            root_ready <= 0;
            i <= 0;
            q <= 0;
            {ac, x} <= {{WIDTH{1'b0}}, operand_1, 2'b0};
        end

        else if (sqrt_busy)
        begin
            if (i == ITER-1) 
            begin
                sqrt_busy <= 0;
                root_ready <= 1;
                root <= qnew;
            end

            else 
            begin  
                i <= i + 1;
                x <= xnew;
                ac <= acnew;
                q <= qnew;
                root_ready <= 0;
            end
        end
    end

    
    // ------------------ //
    // Multiplier Circuit //
    // ------------------ //   
    reg [64 - 1 : 0] product;
    reg product_ready;

    reg     [15 : 0] multiplierCircuitInput1;
    reg     [15 : 0] multiplierCircuitInput2;
    wire    [31 : 0] multiplierCircuitResult;

    Multiplier multiplier_circuit
    (
        .operand_1(multiplierCircuitInput1),
        .operand_2(multiplierCircuitInput2),
        .product(multiplierCircuitResult)
    );

    reg     [31 : 0] partialProduct1;
    reg     [31 : 0] partialProduct2;
    reg     [31 : 0] partialProduct3;
    reg     [31 : 0] partialProduct4;


    reg [2 : 0] current_mul_phase;
    reg [2 : 0] next_mul_phase;

    always @(posedge clk) 
    begin
        if (operation == `FPU_MUL)  current_mul_phase <= next_mul_phase;
        else                        current_mul_phase <= 'b0;
    end

    always @(*) 
    begin
        next_mul_phase <= 'bz;
        case (current_mul_phase)
            3'b000 :
            begin
                product_ready <= 0;

                multiplierCircuitInput1 <= 'bz;
                multiplierCircuitInput2 <= 'bz;

                partialProduct1 <= 'bz;
                partialProduct2 <= 'bz;
                partialProduct3 <= 'bz;
                partialProduct4 <= 'bz;

                next_mul_phase <= 3'b001;
            end 
            3'b001 : 
            begin
                multiplierCircuitInput1 <= operand_1[15 : 0];
                multiplierCircuitInput2 <= operand_2[15 : 0];
                partialProduct1 <= multiplierCircuitResult;
                next_mul_phase <= 3'b010;
            end
            3'b010 : 
            begin
                multiplierCircuitInput1 <= operand_1[31 : 16];
                multiplierCircuitInput2 <= operand_2[15 : 0];
                partialProduct2 <= multiplierCircuitResult;
                next_mul_phase <= 3'b011;
            end
            3'b011 : 
            begin
                multiplierCircuitInput1 <= operand_1[15 : 0];
                multiplierCircuitInput2 <= operand_2[31 : 16];
                partialProduct3 <= multiplierCircuitResult;
                next_mul_phase <= 3'b100;
            end
            3'b100 : 
            begin
                multiplierCircuitInput1 <= operand_1[31 : 16];
                multiplierCircuitInput2 <= operand_2[31 : 16];
                partialProduct4 <= multiplierCircuitResult;
                next_mul_phase <= 3'b101;
            end
            3'b101 :
            begin
                product <= partialProduct1 + (partialProduct2 << 16) + (partialProduct3 << 16) + (partialProduct4 << 32);
                next_mul_phase <= 3'b000;
                product_ready <= 1;
            end

            default: next_mul_phase <= 3'b000;
        endcase    
    end

endmodule

module Multiplier
(
    input wire [15 : 0] operand_1,
    input wire [15 : 0] operand_2,

    output reg [31 : 0] product
);

    always @(*)
    begin
        product <= operand_1 * operand_2;
    end
endmodule
