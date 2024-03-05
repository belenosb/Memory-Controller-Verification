//Notation
//Module chain will be denoted by C[#], where # is either 1 or 2 
//[M1C2] is read "Module 1, chain 2" to denote chain location

//ID 5; ensure test cases of reset in all states
covergroup cg_reset_in_all_states @(posedge tb.rst);
  cp_ps: coverpoint tb.iDUT.mstate{
    bins all_states[] = {[0:17]};
  }
endgroup

//ID 8; M1 can interrupt M2 and M3, bins for each possible interrupt scenario
covergroup cg_M1_can_interrupt @(posedge tb.clk);
  cp_M2state_interrupts_M1state : coverpoint tb.iDUT.mstate{             
    bins M2C1_to_M1C1  = (5'b100 => 5'b1000);                          //[M2in_2p => M1it_2p]
    bins M2C2_to_M1C2  = (5'b101 => 5'b1001);                          //[M2in_2p => M1it_3p]
  }
  cp_M3state_interrupts_M1state : coverpoint tb.iDUT.mstate{
    bins M3C1_to_M1C1  = (5'b110 => 5'b1000);                          //[M3in_2p => M1it_2p]
    bins M3C2_to_M1C2  = (5'b111 => 5'b1001);                          //[M3in_3p => M1it_3p]
  }
endgroup

//ID 16; if M1 interrupt can hold memory at most 2 cycles
covergroup cg_M1_interrupt_limit @(posedge tb.clk);
  cp_mstate: coverpoint tb.iDUT.mstate{
    bins m2p2 =(5'b100=>5'b1010);
    bins m2p3 =(5=>11);
    bins m3p2 =(6=>10);
    bins m3p3 =(7=>11);
    }
endgroup

//ID 24; M2 and M3 cannot interrupt, bins checking for interruption conditions to arise
//illegal bins to check for transition into invalid interrupting module occurs
covergroup cg_M2_and_M3_cannot_interrupt @(posedge tb.clk);
  cp_present_state_M1_interruptable : coverpoint tb.iDUT.ps{
    bins present_state_M1in_2p  = {18'b100};                           //[M1in_2p]
    bins present_state_M1in_3p  = {18'b1000};                          //[M1in_3p]
    bins present_state_M1it_2p  = {18'b100000000};                     //[M1it_2p]
    bins present_state_M1it_3p  = {18'b1000000000};                    //[M1it_3p]
    bins present_state_M1id_2p  = {18'b10000000000};                   //[M1id_2p]
    bins present_state_M1id_3p  = {18'b100000000000};                  //[M1id_3p]
  }
    cp_present_state_M2_interruptable : coverpoint tb.iDUT.ps{
    bins present_state_M2in_2p  = {18'b10000};                         //[M2in_2p]
    bins present_state_M2in_3p  = {18'b100000};                        //[M2in_3p]
  }
    cp_present_state_M3_interruptable : coverpoint tb.iDUT.ps{
    bins present_state_M3in_2p  = {18'b1000000};                       //[M3in_2p]
    bins present_state_M3in_3p  = {18'b10000000};                      //[M3in_3p]
  }
  cp_M1_not_done : coverpoint tb.iDUT.done{
    wildcard bins M1_not_done = {3'b??0};                              //done[??0]100
  }
  cp_M2_not_done : coverpoint tb.iDUT.done{
    wildcard bins M2_not_done = {3'b?0?};                              //done[?0?]
  }
  cp_M3_not_done : coverpoint tb.iDUT.done{
    wildcard bins M3_not_done = {3'b0??};                              //done[0??]
  }
  cp_request_M2_and_M3 : coverpoint tb.iDUT.req{
    bins M2_request = {3'b010};                                        //req[MTWO]
    bins M3_request = {3'b100};                                        //req[MTHREE]
    bins M2_and_M3_request = {3'b110};                                 //req[MTWO] && req[MTHREE]
  }
  cp_next_module_intruder : coverpoint tb.iDUT.ns{
    bins next_state_M2in_2p  = {18'b100};                              //[M2in_2p]
    bins next_state_M2in_3p  = {18'b1000};                             //[M2in_3p]
    bins next_state_M3in_2p  = {18'b10000};                            //[M3in_2p]
    bins next_state_M3in_3p  = {18'b100000};                           //[M3in_3p]
  }
  
  cross_M1_interruptable_notDone_M2andM3_request : cross cp_present_state_M1_interruptable, cp_M1_not_done, cp_request_M2_and_M3, cp_next_module_intruder{
    ignore_bins not_relevant_bins_intruder = binsof(cp_next_module_intruder);
    illegal_bins ib_interruptable_state_M2_M3_request_selfNotDone = binsof(cp_next_module_intruder);
  }
  cross_M2_interruptable_notDone_M2andM3_request : cross cp_present_state_M2_interruptable, cp_M2_not_done, cp_request_M2_and_M3, cp_next_module_intruder{
    ignore_bins not_relevant_bins_intruder = binsof(cp_next_module_intruder);
    illegal_bins ib_interruptable_state_M2_M3_request_selfNotDone = binsof(cp_next_module_intruder);
  }
  cross_M3_interruptable_notDone_M2andM3_request : cross cp_present_state_M3_interruptable, cp_M3_not_done, cp_request_M2_and_M3, cp_next_module_intruder{
    ignore_bins not_relevant_bins_intruder = binsof(cp_next_module_intruder);
    illegal_bins ib_interruptable_state_M2_M3_request_selfNotDone = binsof(cp_next_module_intruder);
  }
endgroup


//ID 36; No gap (i.e., IDLE_#p state) in-between <done> module and different <requesting> module in same cycle
//Bins to check if interruptible module is done and request from M2 and M3 in same cycle occurs
//Illegal bins to check for transition to IDLE#p state
covergroup cg_smooth_transition_no_idle @(posedge tb.clk);
  cp_M1_interruptable : coverpoint tb.iDUT.ps{
    bins present_state_M1in_2p  = {18'b100};                           //[M1in_2p]
    bins present_state_M1in_3p  = {18'b1000};                          //[M1in_3p]
    bins present_state_M1it_2p  = {18'b100000000};                     //[M1it_2p]
    bins present_state_M1it_3p  = {18'b1000000000};                    //[M1it_3p]
    bins present_state_M1id_2p  = {18'b10000000000};                   //[M1id_2p]
    bins present_state_M1id_3p  = {18'b100000000000};                  //[M1id_3p]
    bins present_state_M1sd_2p  = {18'b1000000000000};                 //[M1sd_2p]
    bins present_state_M1sd_3p  = {18'b10000000000000};                //[M1sd_3p]
  }
    cp_M2_interruptable : coverpoint tb.iDUT.ps{
    bins present_state_M2in_2p  = {18'b10000};                         //[M2in_2p]
    bins present_state_M2in_3p  = {18'b100000};                        //[M2in_3p]
    bins present_state_M2sd_2p  = {18'b100000000000000};               //[M2sd_2p]
    bins present_state_M2sd_3p  = {18'b1000000000000000};              //[M2sd_3p]
  }
    cp_M3_interruptable : coverpoint tb.iDUT.ps{
    bins present_state_M3in_2p  = {18'b1000000};                       //[M3in_2p]
    bins present_state_M3in_3p  = {18'b10000000};                      //[M3in_3p]
    bins present_state_M3sd_2p  = {18'b10000000000000000};             //[M3sd_2p]
    bins present_state_M3sd_3p  = {18'b100000000000000000};            //[M3sd_3p]
  }
    cp_M1_done : coverpoint tb.iDUT.done{
    wildcard bins M1_done = {3'b??1};                                  //done[M1]
  }
  cp_M2_done : coverpoint tb.iDUT.done{
    wildcard bins M2_done = {3'b?1?};                                  //done[M2]
  }
  cp_M3_done : coverpoint tb.iDUT.done{
    wildcard bins M3_done = {3'b1??};                                  //done[M3]
  }
    cp_request_M2_and_M3 : coverpoint tb.iDUT.req{
    bins M2_request = {3'b010};                                        //req[MTWO]
    bins M3_request = {3'b100};                                        //req[MTHREE]
    bins M2_and_M3_request = {3'b110};                                 //req[MTWO] && req[MTHREE]
  }
  cp_request_M1_and_M3 : coverpoint tb.iDUT.req{
    bins M1_request = {3'b001};                                        //req[MONE]
    bins M3_request = {3'b100};                                        //req[MTHREE]
    bins M1_and_M3_request = {3'b101};                                 //req[MONE] && req[MTHREE]
  }
  cp_request_M1_and_M2 : coverpoint tb.iDUT.req{
    bins M1_request = {3'b001};                                        //req[MONE]
    bins M2_request = {3'b010};                                        //req[MTWO]
    bins M1_and_M2_request = {3'b011};                                 //req[MONE] && req[MTWO]
  }
  cp_accmodule_clean_transfer : coverpoint tb.iDUT.accmodule{             
    bins IDLE_to_M1 = (2'b00 => 2'b01);                                //[IDLE => M1]
    bins IDLE_to_M2 = (2'b00 => 2'b10);                                //[IDLE => M2]
    bins IDLE_to_M3 = (2'b00 => 2'b11);                                //[IDLE => M3]
    bins M1_to_IDLE = (2'b01 => 2'b00);                                //[M1 => IDLE]
    bins M1_to_M2  = (2'b01 => 2'b10);                                 //[M1 => M2]
    bins M1_to_M3  = (2'b01 => 2'b11);                                 //[M1 => M3]
    bins M2_to_IDLE = (2'b10 => 2'b00);                                //[M2 => IDLE]
    bins M2_to_M1  = (2'b10 => 2'b01);                                 //[M2 => M1]
    bins M2_to_M3  = (2'b10 => 2'b11);                                 //[M2 => M3]
    bins M3_to_IDLE = (2'b11 => 2'b00);                                //[M3 => IDLE]
    bins M3_to_M1  = (2'b11 => 2'b01);                                 //[M3 => M1]
    bins M3_to_M2  = (2'b11 => 2'b10);                                 //[M3 => M2]  
  }
  cross_M1_M1done_and_M2M3_request : cross cp_M1_interruptable, cp_M1_done, cp_request_M2_and_M3, cp_accmodule_clean_transfer{
    ignore_bins not_relevant_bins_M1 = binsof(cp_accmodule_clean_transfer);
    illegal_bins ib_M1_to_M2_or_M3_through_IDLE = binsof(cp_accmodule_clean_transfer.M1_to_IDLE);
  }
  
  cross_M2_M2done_and_M1M3_request : cross cp_M2_interruptable, cp_M2_done, cp_request_M1_and_M3, cp_accmodule_clean_transfer{
    ignore_bins not_relevant_bins_M2 = binsof(cp_accmodule_clean_transfer);
    illegal_bins ib_M2_to_M1_or_M3_through_IDLE = binsof(cp_accmodule_clean_transfer.M2_to_IDLE);
  }
  
  cross_M3_M3done_and_M1M2_request : cross cp_M3_interruptable, cp_M3_done, cp_request_M1_and_M2, cp_accmodule_clean_transfer{
    ignore_bins not_relevant_bins_M3 = binsof(cp_accmodule_clean_transfer);
    illegal_bins ib_M3_to_M1_or_M2_through_IDLE = binsof(cp_accmodule_clean_transfer.M3_to_IDLE);
  }
endgroup  

