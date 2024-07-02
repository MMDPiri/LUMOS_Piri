<!-- <img src="https://github.com/IUST-Computer-Organization/.github/blob/main/images/CompOrg_orange.png" alt="Image" width="85" height="85" style="vertical-align:middle"> LUMOS RISC-V -->
Computer Organization - Spring 2024
==============================================================
## Iran Univeristy of Science and Technology
## Assignment 1: Assembly code execution on phoeniX RISC-V core

- Name: Mohammadreza Piri Sangdeh
- Team Members:Mobina Lashgari - Sara Dadashi
- Student ID: 99411218
- Date:1403/4/12



## SQRT Part

The first part of the Verilog code describes a **square root circuit**. The functionality breakdown is as follows:

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
            begin  // we're done
                sqrt_busy <= 0;
                root_ready <= 1;
                root <= qnew;
            end

            else 
            begin  // next iteration
                i <= i + 1;
                x <= xnew;
                ac <= acnew;
                q <= qnew;
                root_ready <= 0;
            end
        end
    end

    
1. **Registers and Signals**:
   - `root`: A register of width `WIDTH` that holds the square root value.
   - `root_ready`: A flag indicating whether the square root result is ready.
   - `current_square_phase` and `next_square_phase`: Two 2-bit registers used to manage the stages of the square root computation.

2. **Clock-Driven Logic**:
   - The `always @(posedge clk)` block handles clock-driven behavior.
   - If the operation is a square root (`operation == `FPU_SQRT``), it updates the `current_square_phase` based on the next stage value.
   - Otherwise, it resets `current_square_phase` to `2'b00` and clears `root_ready`.

3. **Combinational Logic**:
   - The `always @(*)` block is combinatorial (sensitivity to any change in inputs).
   - It determines the next value of `next_square_phase` based on the current `current_square_phase`.
   - Other signals (`sqrt_start`, `sqrt_busy`, `x`, `q`, `ac`, `test_res`, `valid`, etc.) are also updated based on various conditions.

4. **Square Root Computation**:
   - The circuit computes the square root of an input value (`operand_1`) using the Newton-Raphson method.
   - It iteratively refines the approximation of the square root.
   - The iteration count is determined by `ITER`.
   - The final result is stored in `root`.

5. **Overall Behavior**:
   - When `sqrt_function_begin` is asserted, the circuit initializes the computation.
   - It proceeds through iterations until reaching the desired accuracy.
   - Once done, it sets `root_ready` and stores the result in `root`.



 ## Multiplication Part

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

The second part of the Verilog code describes a **Multiplier Circuit**. The functionality breakdown is as follows:

1. **Module Overview**:
   - The code defines two modules: the top-level module (unnamed) and `Multiplier`.
   - The top-level module contains the logic for a multi-phase multiplier circuit.
   - The `Multiplier` module computes the product of two 16-bit operands.

2. **Top-Level Module**:
   - Registers and wires:
     - `product`: A 64-bit register to store the final product.
     - `product_ready`: A flag indicating when the product is ready.
     - `multiplierCircuitInput1` and `multiplierCircuitInput2`: 16-bit registers for input operands.
     - `multiplierCircuitResult`: A 32-bit wire for the result from the `Multiplier` module.
   - Instantiation:
     - An instance of the `Multiplier` module is created (`multiplier_circuit`).
     - It connects the inputs and output between the top-level module and the `Multiplier` module.

3. **Multiplication Phases**:
   - The multiplication process occurs in multiple phases (`current_mul_phase`):
     - Phase 0 (`3'b000`): Initialization.
     - Phase 1 (`3'b001`): Multiply the lower 16 bits of operands.
     - Phase 2 (`3'b010`): Multiply the upper 16 bits of operand 1 with the lower 16 bits of operand 2.
     - Phase 3 (`3'b011`): Multiply the lower 16 bits of operand 1 with the upper 16 bits of operand 2.
     - Phase 4 (`3'b100`): Multiply the upper 16 bits of operands.
     - Phase 5 (`3'b101`): Combine partial products to compute the final 64-bit product.
       - `partialProduct1`, `partialProduct2`, `partialProduct3`, and `partialProduct4` store intermediate results.
       - The final product is calculated as: $$\text{product} = \text{partialProduct1} + (\text{partialProduct2} \ll 16) + (\text{partialProduct3} \ll 16) + (\text{partialProduct4} \ll 32)$$.

4. **Multiplier Module**:
   - The `Multiplier` module computes the product of two 16-bit operands (`operand_1` and `operand_2`).
   - It directly multiplies the operands using the expression `product <= operand_1 * operand_2`.

In summary, this Verilog code implements a multi-phase multiplier circuit that computes the product of two 32-bit numbers. The result is stored in the `product` register, and the `product_ready` flag indicates when the computation is complete.
## Validation

