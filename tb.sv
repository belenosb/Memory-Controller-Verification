`timescale 1ns/1ns
`include "covergroups.sv"

class randomInputs;
  rand bit[2:0] req;
  rand bit[2:0] done;
  rand bit rst;
  rand integer chance0;
  rand bit skipCycle;
  bit [2:0] reqCooldown = 3'b0;
  bit [2:0] doneCooldown = 3'b0;
  
  constraint chance0_is_100 {
    chance0 inside {[0:100]};
  }

  //Contraining inputs per REQ16 illegal(!(req[n] == done[n] == 1))
  constraint req0H_notEqual_done0H {
    (req[0] == 1) -> (done[0] != 1);
    (done[0] == 1) -> (req[0] != 1);
  }
  constraint req1H_notEqual_done1H {
    (req[1] == 1) -> (done[1] != 1);
    (done[1] == 1) -> (req[1] != 1);
  }
  constraint req2H_notEqual_done2H {
    (req[2] == 1) -> (done[2] != 1);
    (done[2] == 1) -> (req[2] != 1);
  }
  //constraint prob_M1_request {(req[0]) dist {1:=30,0:=70};}
  
  //Constraining request and done bits into cooldown (ensure clean pulses)
  constraint cooldownBits {
    (reqCooldown[0] == 1) -> (req[0] == 0);
    (reqCooldown[1] == 1) -> (req[1] == 0);
    (reqCooldown[2] == 1) -> (req[2] == 0);
    (doneCooldown[0] == 1) -> (done[0] == 0);
    (doneCooldown[1] == 1) -> (done[1] == 0);
    (doneCooldown[2] == 1) -> (done[2] == 0);
  }
  
endclass

module tb();
  logic [2:0] req; 
  logic [2:0] done;
  logic clk, rst;  // Input signals to the DUT.
  logic [4:0] mstate;
  logic [1:0] accmodule;
  integer nb_interrupts;
  logic sclk;

  //[Boli modified controller name]
  controller iDUT(.req(req), .done(done), .reset(rst), .clk(clk), .mstate(mstate), .accmodule(accmodule), .nb_interrupts(nb_interrupts));

  
  //Parameters
  parameter PERIOD = 20;
  parameter LOOP_COUNT = 100;              //number of constrained random input "runs'
  parameter TTL = 100;                    //time to live: number of random input runs before reset
  
  always
    #(PERIOD/2) clk = ~clk;

  always
    #(PERIOD/20) sclk = ~sclk;

  //covergroup initialization
  cg_reset_in_all_states cg_reset_in_all_states_0;
  cg_M1_can_interrupt cg_M1_can_interrupt_0;
  cg_M2_and_M3_cannot_interrupt cg_M2_and_M3_cannot_interrupt_0;
  cg_smooth_transition_no_idle cg_smooth_transition_no_idle_0;
  
  //run-all case
  cg_reset_in_all_states cg_reset_in_all_states_1;
  cg_M1_can_interrupt cg_M1_can_interrupt_1;
  cg_M2_and_M3_cannot_interrupt cg_M2_and_M3_cannot_interrupt_1;
  cg_smooth_transition_no_idle cg_smooth_transition_no_idle_1;

  //random Input
  randomInputs rand_inputs;

initial begin
  //Initializing testbench
  clk = 0;
  sclk = 0;
  rst = 1;
  req = 3'b000;
  done = 3'b000;
  # PERIOD rst = 0;
  
  //random input initialization and seed
  rand_inputs = new;
  rand_inputs.srandom(1234);                                              //[srandom]standard seed = 1234 

  //Test ID Case 5; test coverage for request M1, M2 and M3 [req]
  if ($test$plusargs("tc_reset_in_all_states") || $test$plusargs("allcases")) begin
    $display ("\n[tc_reset_in_all_states] test case with ID = 5 is recognized");
    cg_reset_in_all_states_0 = new();
    for (int i = 0; i < LOOP_COUNT; i++)begin                                     //number of randomized input tests(50)
      # (2*PERIOD) rst = 1'b1;
      # (PERIOD) rst = 1'b0;
      for (int j = 0; j < TTL; j++)begin                                      //1000 cycles per testcase
        rand_inputs.randomize();                                          //randomize inputs    
        
        rand_inputs.doneCooldown = 3'b0;                                    //reset cooldowns
        rand_inputs.reqCooldown = 3'b0;
        # (rand_inputs.skipCycle * PERIOD) req = rand_inputs.req;       
        done = rand_inputs.done;
        for (int k = 0; k < 3; k++)begin                                            //no re-request
          if(req[k] == 1)begin
            rand_inputs.reqCooldown[k] = 1;
          end
          if(done[k] == 1)begin
            rand_inputs.doneCooldown[k] = 1;
          end
        end
        if(rand_inputs.chance0 >= 90)begin
          rst = 1'b1;
          # (PERIOD) rst = 1'b0;
        end
        # (PERIOD) req = 3'b000;       
        done = 3'b000;
      end
    end
  $display ("\n[tc_reset_in_all_states] test case with ID = 5 is completed\n");
  end
  
  //Test ID 8; M1 can interrupt M2 and M3
  if ($test$plusargs("tc_M1_can_interrupt") || $test$plusargs("allcases")) begin
    $display ("\n[tc_M1_can_interrupt] test case with ID = 8 is recognized");
    cg_M1_can_interrupt_0 = new();
    for (int i = 0; i < LOOP_COUNT; i++)begin                                     //number of randomized input tests(50)
      # (2*PERIOD) rst = 1'b1;
      # (PERIOD) rst = 1'b0;
      for (int j = 0; j < TTL; j++)begin                                      //1000 cycles per testcase
        rand_inputs.randomize();                                          //randomize inputs    
        rand_inputs.doneCooldown = 3'b0;                                    //reset cooldowns
        rand_inputs.reqCooldown = 3'b0;
        # (rand_inputs.skipCycle * PERIOD) req = rand_inputs.req;       
        done = rand_inputs.done;
        for (int k = 0; k < 3; k++)begin                                            //no re-request
          if(req[k] == 1)begin
            rand_inputs.reqCooldown[k] = 1;
          end
          if(done[k] == 1)begin
            rand_inputs.doneCooldown[k] = 1;
          end
        end
        if(rand_inputs.chance0 >= 90)begin
          rst = 1'b1;
          # (PERIOD) rst = 1'b0;
        end
        # (PERIOD) req = 3'b000;       
        done = 3'b000;
      end
    end
  $display ("\n[tc_M1_can_interrupt] test case with ID = 8 is completed\n");
  end
  
  //ID 24; M2 and M3 cannot interrupt other modules
  if ($test$plusargs("tc_M2_and_M3_cannot_interrupt") || $test$plusargs("allcases")) begin
    $display ("\n[tc_M2_and_M3_cannot_interrupt] test case with ID = 24 is recognized");
    cg_M2_and_M3_cannot_interrupt_0 = new();
    for (int i = 0; i < LOOP_COUNT; i++)begin                                     //number of randomized input tests(50)
      # (2*PERIOD) rst = 1'b1;
      # (PERIOD) rst = 1'b0;
      for (int j = 0; j < TTL; j++)begin                                      //1000 cycles per testcase
        rand_inputs.randomize();                                          //randomize inputs    
        rand_inputs.doneCooldown = 3'b0;                                    //reset cooldowns
        rand_inputs.reqCooldown = 3'b0;
        # (rand_inputs.skipCycle * PERIOD) req = rand_inputs.req;       
        done = rand_inputs.done;
        for (int k = 0; k < 3; k++)begin                                            //no re-request
          if(req[k] == 1)begin
            rand_inputs.reqCooldown[k] = 1;
          end
          if(done[k] == 1)begin
            rand_inputs.doneCooldown[k] = 1;
          end
        end
        if(rand_inputs.chance0 >= 90)begin
          rst = 1'b1;
          # (PERIOD) rst = 1'b0;
        end
        # (PERIOD) req = 3'b000;       
        done = 3'b000;
      end
    end
    $display ("\n[tc_M2_and_M3_cannot_interrupt] test case with ID = 24 is completed\n");
    end
  
  //ID 36; No gap in-between <done> module and different <requesting> module in same cycle
  if ($test$plusargs("tc_smooth_transition_no_idle") || $test$plusargs("allcases")) begin
  $display ("\n[tc_smooth_transition_no_idle] test case with ID = 36 is recognized");
  cg_smooth_transition_no_idle_0 = new();
    for (int i = 0; i < LOOP_COUNT; i++)begin                                     //number of randomized input tests(50)
      # (2*PERIOD) rst = 1'b1;
      # (PERIOD) rst = 1'b0;
      for (int j = 0; j < TTL; j++)begin                                      //1000 cycles per testcase
        rand_inputs.randomize();                                          //randomize inputs    
        rand_inputs.doneCooldown = 3'b0;                                    //reset cooldowns
        rand_inputs.reqCooldown = 3'b0;
        # (rand_inputs.skipCycle * PERIOD) req = rand_inputs.req;       
        done = rand_inputs.done;
        for (int k = 0; k < 3; k++)begin                                            //no re-request
          if(req[k] == 1)begin
            rand_inputs.reqCooldown[k] = 1;
          end
          if(done[k] == 1)begin
            rand_inputs.doneCooldown[k] = 1;
          end
        end
        if(rand_inputs.chance0 >= 90)begin
          rst = 1'b1;
          # (PERIOD) rst = 1'b0;
        end
        # (PERIOD) req = 3'b000;       
        done = 3'b000;
      end
    end
    $display ("\n[tc_smooth_transition_no_idle] test case with ID = 36 is completed\n");
    end
          
  # 20 $dumpflush;
  $stop;

end

initial begin
  $dumpfile("test.vcd");
  $dumpvars(1, tb);
end

endmodule

bind tb.iDUT controller_assertions sva_0(.*);

