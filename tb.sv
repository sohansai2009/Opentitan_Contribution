// Code your testbench here
// or browse Examples


module tb;
  logic clk,rst,in1,in2,out1,out2;
  gf dut(clk,rst,in1,in2,out1,out2);
  
  //define clock signal
  initial
    begin
      clk=0;
    end
  
  always #5 clk=~clk;
  

   
  initial
    begin
      rst=1;
      #10;
      rst=0; 
      for(int i=0;i<20;i++)
        begin
          in2=$urandom_range(0,1);
        end
    end
  
  initial
    begin
      in1=0;
      repeat(5) @(posedge clk);
      in1=1;
      repeat(5) @(posedge clk);
      in1=0;
      repeat(2) @(posedge clk);
      in1=1;
      repeat(5) @(posedge clk);
      in1=0;
      repeat(1) @(posedge clk);
      in1=1;
      repeat(5) @(posedge clk);
      in1=0;
      repeat(2) @(posedge clk);
      in1=1;
      repeat(2) @(posedge clk);
      in1=0;
      repeat(5) @(posedge clk);
      in1=1;
    end
  
  initial
    begin
      $dumpfile("test.vcd");
      $dumpvars(0);
      #500;
      $finish;
    end
endmodule
      
