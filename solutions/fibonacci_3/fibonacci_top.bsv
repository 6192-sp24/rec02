import Fibonacci::*;

// Recompile and rerun?
// make clean fibonacci_top; ./fibonacci_top

module fibonacci_top(Empty);  // Version 2.0: Variable number, our top module uses only once.
    Fibonacci fibonacci <- mkFibonacci;
    Reg#(Bool) started <- mkReg(False);

    Reg#(Bit#(8)) n <- mkReg(8);

    // Test bench suitable for one call only
    rule start if (!started);
        fibonacci.start(n);
        started <= True;
    endrule

    rule terminate if (started);
        let val <- fibonacci.get();
        $display("We got %0d for %0dth number", val, n);
        $finish;  // Instructs the simulation to stop.
    endrule

endmodule