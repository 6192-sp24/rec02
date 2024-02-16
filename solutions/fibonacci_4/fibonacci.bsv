import BRAM::*;

interface Fibonacci;
    method Action start(Bit#(8) n);
    method ActionValue#(Bit#(32)) get();
endinterface

typedef enum {
    // Setup,
    Idle,
    Checking,
    Working,
    Returning
} State deriving (Bits, Eq, FShow);

module mkFibonacci(Fibonacci);  // Version 4: Cached Version
    BRAM_Configure cfg = defaultValue;

    // How much can we hold in this BRAM for our problem?
    BRAM1Port#(Bit#(8), Bit#(32)) cache <- mkBRAM1Server(cfg);  // "cache" version A
    // Is it realistic hardware?

    // Another way to do it
    // BRAM1Port#(Bit#(4), Vector#(16, Bit#(32))) different_cache <- mkBRAM1Server(cfg);  // "cache" version B

    // [not demonstrated] // cache version C can be a conventional cache smaller
    // than the memory, w/ tags and valids and such

    // Plan:
    // - We initialize
    //      - What happens if we don't?
    //      - What do we initialize with?
    //      - How long does it take to initialize?
    // - We receive request, first we see if we have it.
    // - If we get a miss, then we start the process from the beginning.

    Reg#(Bit#(32)) a <- mkReg(1);
    Reg#(Bit#(32)) b <- mkReg(0);

    // Counter for however many cyicles we need
    Reg#(Bit#(8)) current <- mkReg(0);
    Reg#(Bit#(8)) target <- mkRegU;

    // Enum based state
    Reg#(State) state <- mkReg(Idle);

    // Little flag for making things more verbose.
    Reg#(Bool) debug <- mkReg(False);
    Reg#(Bit#(32)) cycle <- mkReg(0);

    rule debug_tick if (debug);
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
        if (debug) $display("[0;34mAll complete[0m");
        state <= Returning;
    endrule

    // TODO ??? 😉

    rule check if (state == Checking);
        let response <- cache.portA.response.get();
        $display("Cache req for %0d returned %0d", target, response);
        // Current bad implementation; assumes we always get a cache hit.
        state <= Idle;
    endrule

    method Action start(Bit#(8) n) if (state == Idle);
        $display("[0;35mStarting check: target %0d[0m", n);
        a <= 1;
        b <= 0;

        current <= 0;
        target <= n;
        
        let req = BRAMRequest {
            write: False,
            address: n
            };
        cache.portA.request.put(req);
            
        state <= Checking;
    endmethod

    method ActionValue#(Bit#(32)) get() if (state == Returning);
        state <= Idle;
        $display("Retrieving answer %0d", a);
        return a;
    endmethod

endmodule