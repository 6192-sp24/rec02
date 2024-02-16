module fibonacci(Empty);  // Version 1: Hardcoded number
    Reg#(Bit#(16)) a <- mkReg(1);
    Reg#(Bit#(16)) b <- mkReg(0);

    Reg#(Bit#(4)) count <- mkReg(0);

    rule tick if (count < 15);
        let new_sum = a + b;  // Placed into variable because we use it twice

        $display("%d", new_sum);  // Human-readable printf-style

        a <= new_sum;
        b <= a;
        count <= count + 1;
    endrule

    rule terminate if (count == 15);
        $display("We're done!");
        $finish;  // Instructs the simulation to stop.
    endrule

endmodule