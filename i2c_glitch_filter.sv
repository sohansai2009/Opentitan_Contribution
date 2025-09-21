// Code your design here


module i2c_glitch_filter(clk,rst,in1,in2,out1,out2);
  input logic clk,rst;
  input logic  in1,in2; //serial data input (in1->scl, in2->sda)
  output logic out1,out2; //serial data output (out1->scl, out2->sda)
  
  parameter n1=5; //requirement for min number of clock cycles(for scl)
  parameter n2=3; //for sda
  
  //define states (for scl)
  typedef enum logic [1:0] {reset_scl,idle_scl,counting_scl,d_state_scl} type_state_scl;
  type_state_scl state_scl=reset_scl;
  type_state_scl next_state_scl=reset_scl;
  
  //state declaration (for sda)
  typedef enum logic [1:0] {reset_sda,idle_sda,counting_sda,d_state_sda} type_state_sda;
  type_state_sda state_sda=reset_sda;
  type_state_sda next_state_sda=reset_sda;
  
  //count tracker
  logic [2:0] count1,count2;
  logic reg1,reg2; //temp reg
  
  
  //define state values
  always_ff @(posedge clk or negedge rst)
    begin
      if(!rst)
        begin
          state_scl<=next_state_scl;
          state_sda<=next_state_sda;
        end
      else
        begin
          state_scl<=reset_scl;
          state_sda<=reset_sda;
        end
    end
  
  
  //define state transition for scl
  always_comb begin
    case(state_scl)
      reset_scl: next_state_scl=idle_scl;
      idle_scl: next_state_scl=((out1==in1))?idle_scl:counting_scl;
      counting_scl: next_state_scl=((count1==n1 && in1==reg1) ||(in1!=reg1))? d_state_scl:counting_scl;
      d_state_scl: next_state_scl=idle_scl;
    endcase
  end
  
  
  //state transistion for sda
  always_comb begin
    case(state_sda)
      reset_sda : next_state_sda=idle_sda;
      idle_sda: next_state_sda=(out2==in2)?idle_sda:counting_sda;
      counting_sda: next_state_sda=((in2==reg2) && (count2==n2) || (in2!=reg2))?d_state_sda:counting_sda;
      d_state_sda: next_state_sda=idle_sda;
    endcase
  end
  
  //state operation for each state in sda
  always_ff @(posedge clk)
    begin
      case(state_sda)
        reset_sda: begin
          out2<=0;
          reg2<=0;
          count2<=1;
        end
        idle_sda: begin
          if(out2!=in2)
            begin
              reg2<=in2;
              count2<=1;
            end
        end
        counting_sda: begin
          if(in2==reg2)
            begin
              count2<=count2+1;
              if(count2==n2)
                begin
                  out2<=reg2;
                end
            end
          else
            begin
              out2<=0;
              count2<=1;
            end
        end
       d_state_sda: begin
          count2<=1;
       end
      endcase
    end

              
  //define the operation in each state for scl
  always_ff @(posedge clk)
    begin
      case(state_scl)
        //reset everything to zero
        reset_scl: begin
          out1<=0;
          reg1<=0;
        end
        
        idle_scl: begin
          if(out1!=in1)
            begin
              reg1<=in1;
              count1<=1;
            end
          else if(out1==in1)
            begin
              reg1<=0;
            end
        end
              
        counting_scl:
          begin
            //check for stability of in1
            if(in1==reg1)
              //only if input value remains same, increment the counter by 1 in each clock cycle
              begin
                count1<=count1+1;
                if(count1==n1) //after n clock cycles, in would be the same, cause, if 'in' was not same, then counter would have reset to 1
                  begin
                    out1<=reg1; //input valid
                  end
              end
            //checking stability for in2  
            else if(in1!=reg1)
             begin
               count1<=1;
               out1<=0;
             end
             
          end
        d_state_scl: begin
          count1<=1;
        end
      endcase
    end
endmodule
  
  
