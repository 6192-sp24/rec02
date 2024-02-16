import Fibonacci::*;
import Vector::*;

// Recompile and rerun?
// make clean fibonacci_top; ./fibonacci_top

module fibonacci_top(Empty);  // Version 2.0: Variable number, our top module uses only once.
    Fibonacci fibonacci <- mkFibonacci;

    Reg#(Bit#(8)) last_req <- mkRegU;
    Reg#(Bit#(8)) stage <- mkReg(0);

    // Some helper functions
    function Action call_start(Bit#(8) n);
    action  // BSC is a little annoying; action/endaction are implicit in methods, but not functions
        last_req <= n;
        fibonacci.start(n);
        stage <= stage + 1;
    endaction
    endfunction

    function Action call_get();
    action
        let val <- fibonacci.get();
        // $display("We got %0d for %0dth number", val, last_req);
    endaction
    endfunction

    // A little bit of state to control our state machine
    // Ok full disclosure, I don't know how to write a real test bench that can
    // test a sequence of method calls.

    // We always get, so we can focus on start
    rule always_get;
        call_get();
    endrule

    // Old-fashioned format
    rule r0(stage == 0);
        call_start(8);
    endrule

    rule r1(stage == 1);
        call_start(8);
    endrule

    // Something a little sneakier

    // These are compiler directives and they're almost always a bad idea
    // because you can easily lose sight of your program. It's just playing
    // with the text of the program.

    // I'm using it because I don't know any better.
    // This can also be called metaprogramming.
    // This is very similar to C macro defines.
`define R_(n, statement) \
    rule r``n``(stage == n); \
        statement; \
    endrule

    `R_(2, call_start(8))
    `R_(3, call_start(5))
    `R_(4, call_start(5))
    `R_(5, call_start(5))
    `R_(6, $finish)

endmodule