interface Fibonacci;
    method Action start(Bit#(8) n);
    method ActionValue#(Bit#(32)) get();
endinterface

typedef enum {
    Idle,
    Working,
    Returning
} State deriving (Bits, Eq, FShow);

module mkFibonacci(Fibonacci);  // Version 3: Same as 2 but with cuter debug messages
    Reg#(Bit#(32)) a <- mkReg(1);
    Reg#(Bit#(32)) b <- mkReg(0);

    // Why can I leave these uninitialized?
    Reg#(Bit#(8)) current <- mkRegU;
    Reg#(Bit#(8)) target <- mkRegU;

    // What could this look like instead? (to manage our state machine)
    Reg#(State) state <- mkReg(Idle);

    Reg#(Bit#(32)) cycle <- mkReg(0);

    rule debug_tick;
        $display("[0;32m-- Cycle %0d [%0d] --[0m", current, cycle);  // for this, then total
        cycle <= cycle + 1;
    endrule

    rule tick if (state == Working && current < target);
        let new_sum = a + b;  // Placed into variable because we use it twice

        $display("cycle %0d -> %0d", current, new_sum);  // Human-readable printf-style

        a <= new_sum;
        b <= a;
        current <= current + 1;
    endrule

    rule complete if (state == Working && current == target);
        $display("[0;34mAll complete[0m");
        state <= Returning;
    endrule

    method Action start(Bit#(8) n) if (state == Idle);
        a <= 1;
        b <= 0;

        current <= 0;
        target <= n;
        state <= Working;
        $display("Starting calculation: target %0d", n);
    endmethod

    method ActionValue#(Bit#(32)) get() if (state == Returning);
        state <= Idle;
        $display("Retrieving answer %0d", a);
        return a;
    endmethod

endmodule