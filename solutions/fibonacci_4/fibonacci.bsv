import BRAM::*;

typedef BRAMRequest#(Bit#(8), Bit#(32)) CacheRequest;
typedef BRAM1Port#(Bit#(8), Bit#(32)) CacheBRAM;

interface Fibonacci;
    method Action start(Bit#(8) n);
    method ActionValue#(Bit#(32)) get();
endinterface

typedef enum {
    Setup,
    Idle,
    Checking,
    Working,
    Returning
} State deriving (Bits, Eq, FShow);

module mkFibonacci(Fibonacci);  // Version 4: Cached Version
    BRAM_Configure cfg = defaultValue;

    // How much can we hold in this BRAM for our problem?
    CacheBRAM cache <- mkBRAM1Server(cfg);  // "cache" version A
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
    Reg#(Bit#(8)) setup_count <- mkReg(0);
    Reg#(Bit#(8)) current <- mkReg(0);
    Reg#(Bit#(8)) target <- mkRegU;

    // Enum based state
    Reg#(State) state <- mkReg(Setup);

    // Little flag for making things more verbose.
    Reg#(Bool) debug <- mkReg(False);
    Reg#(Bit#(32)) cycle <- mkReg(0);

    function CacheRequest make_write(Bit#(8) addr, Bit#(32) datain);
        let req = BRAMRequest {
            write: True,
            responseOnWrite: False,
            address: addr,
            datain: datain
        };
        return req;
    endfunction

    function Action cache_write(Bit#(8) addr, Bit#(32) datain);
    action
        let req = make_write(addr, datain);
        cache.portA.request.put(req);
    endaction
    endfunction

    rule debug_tick if (debug);
        // the '/n' in the print string is a newline
        $display("\n[0;32m-- Cycle %0d [%0d] --[0m", current, cycle);  // for this, then total
        cycle <= cycle + 1;
    endrule

    rule tick if (state == Working && current < target);
        let new_sum = a + b;  // Placed into variable because we use it twice

        $display("cycle %0d -> %0d", current, new_sum);  // Human-readable printf-style

        a <= new_sum;
        b <= a;
        current <= current + 1;

        $display("Writing %0d to cache # %0d", a, current);
        cache_write(current, a);
    endrule

    rule complete if (state == Working && current == target);
        if (debug) $display("[0;34mAll complete[0m");
        state <= Returning;
    endrule

    // TODO ??? 😉 (DONE)
    rule setup if (state == Setup);
        cache_write(setup_count, 0);

        setup_count <= setup_count + 1;
        // $display("Setup count at %0d", setup_count);
        if (setup_count == ~0) begin
            state <= Idle;
        end
    endrule

    rule check if (state == Checking);
        let response <- cache.portA.response.get();
        $display("Cache req for %0d returned %0d", target, response);
        // Current bad implementation; assumes we always get a cache hit.
        
        if (response != 0) begin  // we got a hit
            a <= response;
            state <= Returning;
        end else begin
            state <= Working;
        end
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

        let req = make_write(target, a);
        cache.portA.request.put(req);

        return a;
    endmethod

endmodule