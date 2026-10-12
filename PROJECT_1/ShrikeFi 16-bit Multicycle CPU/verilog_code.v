(* top *) module cpu16 (
    (* iopad_external_pin, clkbuf_inhibit *) input  clk,
    (* iopad_external_pin *) output led,
    (* iopad_external_pin *) output led_en,
    (* iopad_external_pin *) output clk_en
);
 
    assign clk_en = 1'b1;
    assign led_en = 1'b1;
 
    // ---------- start-up hold ----------
    // ready goes high when bit 14 sets = 16384 clocks = ~328 us at 50 MHz,
    // longer than the oscillator's worst-case 213 us settling time.
    reg [14:0] boot = 15'd0;
    wire       ready = boot[14];
    always @(posedge clk)
        if (!ready) boot <= boot + 1'b1;
 
    // ---------- opcodes ----------
    localparam [3:0]
        OP_NOP  = 4'd0,
        OP_ADD  = 4'd1,
        OP_SUB  = 4'd2,
        OP_AND  = 4'd3,
        OP_OR   = 4'd4,
        OP_XOR  = 4'd5,
        OP_ADDI = 4'd6,
        OP_LDI  = 4'd7,
        OP_LD   = 4'd8,
        OP_ST   = 4'd9,
        OP_JMP  = 4'd10,
        OP_BEQ  = 4'd11,
        OP_BNE  = 4'd12,
        OP_OUT  = 4'd13,
        OP_HLT  = 4'd14;
 
    localparam [1:0]
        S_FETCH = 2'd0,
        S_READ  = 2'd1,
        S_EXEC  = 2'd2;
 
    // ---------- CPU state ----------
    reg [1:0]  st      = S_FETCH;
    reg [4:0]  pc      = 5'd0;
    reg [15:0] ir      = 16'd0;
    reg [15:0] opa     = 16'd0;
    reg [15:0] opb     = 16'd0;
    reg [15:0] out_reg = 16'd0;
    reg        halted  = 1'b0;
 
    // R0 always reads as zero
    reg [15:0] regs [1:7];
    reg [15:0] dmem [0:15];
 
    // ---------- instruction ROM: LED blink ----------
    function [15:0] rom_f(input [4:0] a);
        begin
            case (a)
                5'd0:  rom_f = {OP_LDI,  3'd1, 9'd0};                // R1 = 0 (LED state)
                5'd1:  rom_f = {OP_LDI,  3'd3, 9'd64};               // R3 = outer count
                5'd2:  rom_f = {OP_LDI,  3'd2, 9'd1};                // R2 = 1
                5'd3:  rom_f = {OP_XOR,  3'd1, 3'd1, 3'd2, 3'b000};  // R1 ^= 1
                5'd4:  rom_f = {OP_OUT,  3'd1, 9'd0};                // LED = R1
                5'd5:  rom_f = {OP_LDI,  3'd4, 9'd0};                // R4 = 0
                5'd6:  rom_f = {OP_ADDI, 3'd4, 3'd4, 6'h3F};         // R4--
                5'd7:  rom_f = {OP_BNE,  3'd4, 3'd0, 6'd6};          // inner loop
                5'd8:  rom_f = {OP_ADDI, 3'd3, 3'd3, 6'h3F};         // R3--
                5'd9:  rom_f = {OP_BNE,  3'd3, 3'd0, 6'd5};          // outer loop
                5'd10: rom_f = {OP_JMP,  12'd1};                     // repeat forever
                default: rom_f = {OP_JMP, 12'd0};                    // recover: restart
            endcase
        end
    endfunction
 
    wire [15:0] rom = rom_f(pc);
 
    // ---------- instruction decode ----------
    wire [3:0]  op   = ir[15:12];
    wire [2:0]  f1   = ir[11:9];
    wire [2:0]  f2   = ir[8:6];
    wire [2:0]  f3   = ir[5:3];
    wire [8:0]  imm9 = ir[8:0];
    wire [4:0]  tgt  = ir[4:0];
    wire [15:0] simm = {{10{ir[5]}}, ir[5:0]};
 
    // ---------- register selection ----------
    wire [2:0] idxA = (op == OP_BEQ || op == OP_BNE || op == OP_OUT) ? f1 : f2;
    wire [2:0] idxB = (op == OP_BEQ || op == OP_BNE) ? f2 :
                      (op == OP_ST)                  ? f1 : f3;
 
    wire [15:0] rdA = (idxA == 3'd0) ? 16'd0 : regs[idxA];
    wire [15:0] rdB = (idxB == 3'd0) ? 16'd0 : regs[idxB];
 
    // ---------- memory ----------
    wire [3:0]  maddr = opa[3:0] + ir[3:0];
    wire [15:0] mem_q = dmem[maddr];
 
    // ---------- execute ----------
    reg [15:0] wval;
    reg        wen;
 
    always @(*) begin
        wen  = 1'b1;
        wval = 16'd0;
        case (op)
            OP_ADD:  wval = opa + opb;
            OP_SUB:  wval = opa - opb;
            OP_AND:  wval = opa & opb;
            OP_OR:   wval = opa | opb;
            OP_XOR:  wval = opa ^ opb;
            OP_ADDI: wval = opa + simm;
            OP_LDI:  wval = {7'd0, imm9};
            OP_LD:   wval = mem_q;
            default: wen = 1'b0;
        endcase
    end
 
    // ---------- CPU control ----------
    always @(posedge clk) begin
        if (!ready) begin
            // held in reset while the oscillator settles
            st      <= S_FETCH;
            pc      <= 5'd0;
            halted  <= 1'b0;
            out_reg <= 16'd0;
        end else if (!halted) begin
            case (st)
                S_FETCH: begin
                    ir <= rom;
                    st <= S_READ;
                end
 
                S_READ: begin
                    opa <= rdA;
                    opb <= rdB;
                    st  <= S_EXEC;
                end
 
                S_EXEC: begin
                    pc <= pc + 1'b1;
                    if (wen && f1 != 3'd0)
                        regs[f1] <= wval;
                    case (op)
                        OP_ST:  dmem[maddr] <= opb;
                        OP_JMP: pc <= tgt;
                        OP_BEQ: if (opa == opb) pc <= tgt;
                        OP_BNE: if (opa != opb) pc <= tgt;
                        OP_OUT: out_reg <= opa;
                        OP_HLT: begin halted <= 1'b1; pc <= pc; end
                        default: ;
                    endcase
                    st <= S_FETCH;
                end
 
                default: st <= S_FETCH;
            endcase
        end
    end
 
    assign led = out_reg[0];
 
endmodule
 
