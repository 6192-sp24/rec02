interface Fibonacci;
    method Action start(Bit#(8) n);
    method ActionValue#(Bit#(32)) get();
endinterface

module mkFibonacci(Fibonacci);  // Version 2: Variable fibonacci
    Reg#(Bit#(32)) a <- mkReg(1);
    Reg#(Bit#(32)) b <- mkReg(0);

    // Why can I leave these uninitialized?
    Reg#(Bit#(8)) current <- mkRegU;
    Reg#(Bit#(8)) target <- mkRegU;

    // What could this look like instead? (to manage our state machine)
    Reg#(Bool) input_ready <- mkReg(True);
    Reg#(Bool) output_ready <- mkReg(False);

    rule tick if (current < target);
        let new_sum = a + b;  // Placed into variable because we use it twice

        $display("%0d -> %0d", current + 1, new_sum);  // Human-readable printf-style

        a <= new_sum;
        b <= a;
        current <= current + 1;
    endrule

    rule complete if (!input_ready && current == target);
        output_ready <= True;
    endrule

    method Action start(Bit#(8) n) if (input_ready);
        a <= 1;
        b <= 0;

        current <= 0;
        target <= n;
        input_ready <= False;
    endmethod

    method ActionValue#(Bit#(32)) get() if (output_ready);
        output_ready <= False;
        input_ready <= True;
        return a;
    endmethod

endmodule