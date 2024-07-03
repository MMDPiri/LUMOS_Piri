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

    // here is the code for sqrt module
    // reference: https://github.com/IUST-Computer-Organization/Spring-2023/blob/main/Final_Project/RV32IMF_Processor/SQRT_Unit.v

    reg [1 : 0] stage;
    reg [1 : 0] next_stage;

    always @(posedge clk) 
    begin
        if (operation == `FPU_SQRT) stage <= next_stage;
        else                        
        begin
            stage <= 2'b00;
            root_ready <= 0;
        end
    end 

    always @(*) 
    begin
        next_stage <= 0;
        case (stage)
            2'b00 : begin sqrt_start <= 0; next_stage <= 2'b01; end
            2'b01 : begin sqrt_start <= 1; next_stage <= 2'b10; end
            2'b10 : begin sqrt_start <= 0; next_stage <= 2'b10; end
        endcase    
    end

    reg [WIDTH - 1 : 0] x, x_next;              
    reg [WIDTH - 1 : 0] q, q_next;              
    reg [WIDTH + 1 : 0] ac, ac_next;            
    reg [WIDTH + 1 : 0] test_res;               

    reg valid;
    reg sqrt_start;
    reg sqrt_busy;
    

    localparam ITER = (WIDTH + FBITS) >> 1;     
    reg [4 : 0] i = 0;                              

    
    always @(*)
    begin
        test_res = ac - {q, 2'b01};

        if (test_res[WIDTH + 1] == 0) 
        begin
            {ac_next, x_next} = {test_res[WIDTH - 1 : 0], x, 2'b0};
            q_next = {q[WIDTH - 2 : 0], 1'b1};
        end 
        else 
        begin
            {ac_next, x_next} = {ac[WIDTH - 1 : 0], x, 2'b0};
            q_next = q << 1;
        end
    end
    
    always @(posedge clk) 
    begin
        if (sqrt_start)
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
                root <= q_next;
            end

            else 
            begin  // next iteration
                i <= i + 1;
                x <= x_next;
                ac <= ac_next;
                q <= q_next;
                root_ready <= 0;
            end
        end
    end

1. **Registers and Parameters**:
    - `root` and `root_ready` are registers.
    - `stage` and `next_stage` are 2-bit registers representing the state machine.
    - `valid`, `sqrt_start`, and `sqrt_busy` are registers for control signals.
    - `ITER` is a local parameter representing the number of iterations.

2. **Always Block for State Machine**:
    - The first `always @(posedge clk)` block updates the state machine (`stage`) based on the `operation` signal (presumably a square root calculation).
    - If the operation is a square root (`FPU_SQRT`), it transitions to the next stage; otherwise, it resets the stage and sets `root_ready` to 0.

3. **Combinational Logic Block for State Transition**:
    - The second `always @(*)` block computes the next stage (`next_stage`) based on the current stage.
    - It transitions through three stages: `00`, `01`, and `10`, controlling the `sqrt_start` signal.

4. **Square Root Computation Logic**:
    - The code calculates the square root iteratively using the Newton-Raphson method.
    - Variables:
        - `x` represents the radicand.
        - `q` represents the result.
        - `ac` is an accumulator.
        - `test_res` is the difference between `ac` and `{q, 2'b01}`.
    - The algorithm:
        - If `test_res[WIDTH + 1]` is 0, adjust `ac_next` and `x_next`.
        - Otherwise, shift `q` left by 1.
    - The iteration continues until `i` reaches `ITER-1`.
    - The final result is stored in `root`.

5. **Clock-Based Updates**:
    - The second `always @(posedge clk)` block handles control signals during the computation.
    - If `sqrt_start` is active:
        - Initialize variables (`i`, `q`, `ac`, `x`).
        - Set `sqrt_busy` and clear `root_ready`.
    - If `sqrt_busy`:
        - Update variables based on the iteration.
        - When done, set `root_ready` and store the result in `root`.


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
The result for validation of the written code is as follows :

![image](https://github.com/MMDPiri/LUMOS_Piri/assets/169598509/09513b58-fe8e-4465-ab56-92347de5e9d4)

As you could see we have reached the number 1126.295, so the result is correct.
