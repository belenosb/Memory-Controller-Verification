//`ifdef FORMAL

module controller_assertions(
  input clk,
  input reset,
  input [2:0] req,
  input [2:0] done,
  input logic [4:0] mstate, // 1-hot encoded
  input logic [1:0] accmodule,
  input integer nb_interrupts  // nb of interruptions
);

parameter M1=0;
parameter M2=1;
parameter M3=2;

//ID 4 & 66: R#4 Active High Asynchronous reset. 
//If we have a requirement for reset needs to be asserted for one clk cycle then we could use clk as the sampling event
//However, there's no such requirement, so we would use a faster clock to do
//the sampling to catch asynchronous signal of length smaller than the clk period.[[[Maybe sclk]]]
property p4_active_high_async_reset;
  @(posedge tb.sclk)
  reset |-> (
    //all of controller module's output
    (!accmodule) && 
    (nb_interrupts==0) && 
    (mstate==0)
    );
  // mstate == 0 : IDLE_2p
  // mstate == 1 : IDLE_3p
endproperty
fpv_p4_active_high_async_reset: assert property (p4_active_high_async_reset);

//ID 12 & 67: R#8 Requests are evaluated and acted upon on clk posedge. [[[Maybe sclk]]]
property p8_req_action;
  @(posedge tb.sclk) disable iff(reset)
  ( $past(clk, 1) or ($past(!clk,1) and !clk) ) |-> $stable (mstate) ;
endproperty
fpv_p8_req_action: assert property (p8_req_action);

//ID 11a & 64a; R#7 req[M1] is asserted for exactly one cycle; 
property req1_held_one_cycle;
  @(posedge clk) disable iff(reset)
    req[M1] |=> !req[M1];
endproperty
fpv_req1_held_one_cycle: assume property(req1_held_one_cycle) else $error("[req1_held_one_cycle] does not hold");

//ID 11b & 64b; R#7 req[M2] is asserted for exactly one cycle;
property req2_held_one_cycle;
  @(posedge clk) disable iff(reset)
    req[M2] |=> !req[M2];
endproperty
fpv_req2_held_one_cycle: assume property(req2_held_one_cycle) else $error("[req2_held_one_cycle] does not hold");

//ID 11c & 64c; R#7 req[M3] is asserted for exactly one cycle;
property req3_held_one_cycle;
  @(posedge clk) disable iff(reset)
    req[M3] |=> !req[M3];
endproperty
fpv_req3_held_one_cycle: assume property(req3_held_one_cycle) else $error("[req3_held_one_cycle] does not hold");

//Id 65 & 70; R#3 One Hot encoding implementation; [fb_oneHot_encoding] check if one hot (state 0 inclusive)
property fb_oneHot_encoding;
  @(posedge clk) disable iff(reset)
    $onehot0(controller.ps);
endproperty
fpv_fb_oneHot_encoding: assert property(fb_oneHot_encoding) else $error("[fb_oneHot_encoding] does not hold");

//ID 42 & 43; R#16 At no point can req[n] and done[n] be asserted; [p16_never_done_and_req] assert property never req and done
property p16_never_doneN_and_reqN;
  @(posedge clk) disable iff(reset)
    (req & done) == 0;
endproperty
fpv_p16_never_doneN_and_reqN: assume property(p16_never_doneN_and_reqN)else $error("[p16_never_doneN_and_reqN] does not hold");
//cover property(p16_never_doneN_and_reqN);

//Id 47 & 50; R#19 Memory granted to M1 only if requested by M1; [p19_module1_implies_req1] if module changed check for previous request
property p19_module1_implies_req1;
  @(posedge clk) disable iff(reset)
    if($stable(accmodule) == 0)
      (accmodule == 1) |-> $past(req[M1], 1) == 1;
endproperty
fpv_p19_module1_implies_req1: assert property(p19_module1_implies_req1) else $error("[p19_module1_implies_req1] does not hold");
//cover property(p19_module1_implies_req1);

//Id 48 & 51; R#19 Memory granted to M1 only if requested by M2; [p19_module2_implies_req2] if module changed check for previous request
property p19_module2_implies_req2;
  @(posedge clk) disable iff(reset)
    if($stable(accmodule) == 0)
      (accmodule == 2) |-> $past(req[M2], 1) == 1;
endproperty
fpv_p19_module2_implies_req2: assert property(p19_module2_implies_req2) else $error("[p19_module2_implies_req2] does not hold");
//cover property(p19_module2_implies_req2);

//Id 49 & 52; R#19 Memory granted to M3 only if requested by M3; [p19_module3_implies_req3] if module changed check for previous request
property p19_module3_implies_req3;
  @(posedge clk) disable iff(reset)
    if($stable(accmodule) == 0)
      (accmodule == 3) |-> $past(req[M3], 1) == 1;
endproperty
fpv_p19_module3_implies_req3: assert property(p19_module3_implies_req3) else $error("[p19_module3_implies_req3] does not hold");
//cover property(p19_module3_implies_req3);

//NOTE: ID69a,b&c are auxiliary properties it is not intended to be used as a ID yet [[[this is what it is]]]
//ID 69.a & 71; R#15 done[M1] held one cycle; [fb_done1_held_one_cycle] done[1] is held for one cycle
property p15_done1_held_one_cycle;
  @(posedge clk) disable iff(reset)
    done[M1] |=> !done[M1];
endproperty
fpv_p15_done1_held_one_cycle: assume property(p15_done1_held_one_cycle) else $error("[p15_done1_held_one_cycle] does not hold");
//ID 69.b & 71; R#15 done[M2] held one cycle; [fb_done2_held_one_cycle] done[2] is held for one cycle
property p15_done2_held_one_cycle;
  @(posedge clk) disable iff(reset)
    done[M2] |=> !done[M2];
endproperty
fpv_p15_done2_held_one_cycle: assume property(p15_done2_held_one_cycle) else $error("[p15_done2_held_one_cycle] does not hold");
//ID 69.c & 71; R#15 done[M3] held one cycle; [fb_done3_held_one_cycle] done[3] is held for one cycle
property p15_done3_held_one_cycle;
  @(posedge clk) disable iff(reset)
    done[M3] |=> !done[M3];
endproperty
fpv_p15_done3_held_one_cycle: assume property(p15_done3_held_one_cycle) else $error("[p15_done3_held_one_cycle] does not hold");

//Id 22.a & 23.a; R#10 M2 cannot interrupt any module; [p10_M2_didnt_interrupt_M1] property defines non interruption smooth transitions
property p10_M2_didnt_interrupt_M1;
  @(posedge clk) disable iff(reset)
    ((($past(accmodule, 1) == 1) and (accmodule == 2)) |-> 
    (($past(accmodule, 2) == 1) or ($past(done[M1], 1) == 1)));
endproperty
fpv_p10_M2_didnt_interrupt_M1: assert property(p10_M2_didnt_interrupt_M1) else $error("[p10_M2_didnt_interrupt_M1] does not hold");

//Id 22.b & 23.b; R#10 M2 cannot interrupt any module; [p10_M2_didnt_interrupt_M3] property defines non interruption smooth transitions
property p10_M2_didnt_interrupt_M3;
  @(posedge clk) disable iff(reset)
    ((($past(accmodule, 1) == 3) and (accmodule == 2)) |-> (($past(accmodule, 2) == 3) or ($past(done[M3], 1) == 1)));
endproperty
fpv_p10_M2_didnt_interrupt_M3: assert property(p10_M2_didnt_interrupt_M3) else $error("[p10_M2_didnt_interrupt_M3] does not hold");

//Id 22.c & 23.c; R#10 M3 cannot interrupt any module; [p10_M3_didnt_interrupt_M1] property defines non interruption smooth transitions
property p10_M3_didnt_interrupt_M1;
  @(posedge clk) disable iff(reset)
    ((($past(accmodule, 1) == 1) and (accmodule == 3)) |-> (($past(accmodule, 2) == 1) or ($past(done[M1], 1) == 1)));
endproperty
fpv_p10_M3_didnt_interrupt_M1: assert property(p10_M3_didnt_interrupt_M1) else $error("[p10_M3_didnt_interrupt_M1] does not hold");

//Id 22.d & 23.d; R#10 M3 cannot interrupt any module; [p10_M3_didnt_interrupt_M2] property defines non interruption smooth transitions
property p10_M3_didnt_interrupt_M2;
  @(posedge clk) disable iff(reset)
    ((($past(accmodule, 1) == 2) and (accmodule == 3)) |-> (($past(accmodule, 2) == 2) or ($past(done[M2], 1) == 1)));
endproperty
fpv_p10_M3_didnt_interrupt_M2: assert property(p10_M3_didnt_interrupt_M2) else $error("[p10_M3_didnt_interrupt_M2] does not hold");

//ID 30 & 35.a; R#14 Smooth Transition; [fb_M1_done_to_MN_no_idle]smooth transition from M1 to M2_or_M3;
property p14_smooth_transition_M1_to_MN;
  @(posedge clk) disable iff(reset)
    ((accmodule == 1) and (done[M1]) and ((req[M2] == 1) or (req[M3] == 1))) |=> ((accmodule == 2) or (accmodule == 3));
endproperty
fpv_p14_smooth_transition_M1_to_MN: assert property(p14_smooth_transition_M1_to_MN) else $error("[p14_smooth_transition_M1_to_MN] does not hold");

//ID 32 & 35.b; R#14 Smooth Transition; [fb_M2_done_to_MN_no_idle]smooth transition from M2 to M1_or_M3;
property p14_smooth_transition_M2_to_MN;
  @(posedge clk) disable iff(reset)
    ((accmodule == 2) and (done[M2]) and ((req[M1] == 1) or (req[M3] == 1))) |=> ((accmodule == 1) or (accmodule == 3));
endproperty
fpv_p14_smooth_transition_M2_to_MN: assert property(p14_smooth_transition_M2_to_MN) else $error("[p14_smooth_transition_M2_to_MN] does not hold");

//ID 34 & 35.c; R#14 Smooth Transition; [fb_M3_done_to_MN_no_idle]smooth transition from M3 to M1_or_M2;
property p14_smooth_transition_M3_to_MN;
  @(posedge clk) disable iff(reset)
    ((accmodule == 3) and (done[M3]) and ((req[M1] == 1) or (req[M2] == 1))) |=> ((accmodule == 1) or (accmodule == 2));
endproperty
fpv_p14_smooth_transition_M3_to_MN: assert property(p14_smooth_transition_M3_to_MN) else $error("[p14_smooth_transition_M3_to_MN] does not hold");

//ID 28.a & 29.a; R#13 M2 and M3 have two-cycle limit; [fb_M2_cycle_limit] M2 and M3 have two-cycle limit;
property p13_M2_cycle_limit;
  @(posedge clk) disable iff(reset)
    ((accmodule == 2) ##1 (accmodule == 2)) |=> (accmodule != 2);
endproperty
fpv_p13_M2_cycle_limit: assert property(p13_M2_cycle_limit) else $error("[p13_M2_cycle_limit] does not hold");

//ID 28.b & 29.b; R#13 M2 and M3 have two-cycle limit; [fb_M3_cycle_limit] M2 and M3 have two-cycle limit;
property p13_M3_cycle_limit;
  @(posedge clk) disable iff(reset)
    ((accmodule == 3) ##1 (accmodule == 3)) |=> (accmodule != 3);
endproperty
fpv_p13_M3_cycle_limit: assert property(p13_M3_cycle_limit) else $error("[p13_M3_cycle_limit] does not hold");

//ID 15.a & 68.a: R#9 if M1 interrupts M2, it can only hold memory for 2 clk cycles.
property p9_m1_interrupt_m2_limit;
  @(posedge clk) disable iff(reset)
  ((accmodule != 2) ##1 ((accmodule == 2) and (done[M2] == 0) and (req[M1] == 1))) |=>
  ((accmodule == 1) ##1 (accmodule == 1)) |=>
  (accmodule != 1);
endproperty
fpv_p9_m1_interrupt_m2_limit: assert property (p9_m1_interrupt_m2_limit) else $error("[p9_m1_interrupt_m2_limit] does not hold");

//ID 15.b & 68.b: R#9 if M1 interrupts M3, it can only hold memory for 2 clk cycles.
property p9_m1_interrupt_m3_limit;
  @(posedge clk) disable iff(reset)
  ((accmodule != 3) ##1 ((accmodule == 3) and (done[M3] == 0) and (req[M1] == 1))) |=>
  ((accmodule == 1) ##1 (accmodule == 1)) |=>
  (accmodule != 1);
endproperty
fpv_p9_m1_interrupt_m3_limit: assert property (p9_m1_interrupt_m3_limit) else $error("[p9_m1_interrupt_m3_limit] does not hold");

//ID 7.a: R#5 M1 interrupts M2, and claim memory
property p5_m1_interrupt_m2;
  @(posedge clk) disable iff(reset)
  ($rose(req[M2])) |=>
  ((accmodule == 2) and (done[M2] == 0) and (req[M1] == 1)) |=>
  (accmodule == 1);
endproperty
fpv_p5_m1_interrupt_m2: assert property (p5_m1_interrupt_m2) else $error("[p5_m1_interrupt_m2] does not hold");

//ID 7.b: R#5 M1 interrupts M3, and claim memory
property p5_m1_interrupt_m3;
  @(posedge clk) disable iff(reset)
  ($rose(req[M3])) |=>
  ((accmodule == 3) and (done[M3] == 0) and (req[M1] == 1)) |=>
  (accmodule == 1);
endproperty
fpv_p5_m1_interrupt_m3: assert property (p5_m1_interrupt_m3) else $error("[p5_m1_interrupt_m3] does not hold");

//ID 17: R#9 if M1 did not interrupt, can hold memory indefinitely
property p9_m1_can_infinite;
  @(posedge clk) disable iff(reset)
  ((accmodule == 0) and req[M1]) |=>
  ((accmodule == 1) throughout(done[M1]) [->1]) ##1
  (accmodule != 1);
endproperty
fpv_p9_m1_can_infinite: assert property (p9_m1_can_infinite) else $error("[p9_m1_can_infinite] does not hold");

//ID XXX: R#XX eventually will trigger req1
property pXX_req1_eventually;
  @(posedge clk) disable iff(reset)
  ##[0:$] $rose(req[M1]);
endproperty
fpv_pXX_req1_eventually: assume property (pXX_req1_eventually) else $error("[pXX_req1_eventually] does not hold");

//ID XXX: R#XX eventually will trigger req2
property pXX_req2_eventually;
  @(posedge clk) disable iff(reset)
  ##[0:$] $rose(req[M2]);
endproperty
fpv_pXX_req2_eventually: assume property (pXX_req2_eventually) else $error("[pXX_req2_eventually] does not hold");

//ID XXX: R#XX eventually will trigger req3
property pXX_req3_eventually;
  @(posedge clk) disable iff(reset)
  ##[0:$] $rose(req[M3]);
endproperty
fpv_pXX_req3_eventually: assume property (pXX_req3_eventually) else $error("[pXX_req3_eventually] does not hold");

//ID XXX: R#XX eventually will trigger done1
property pXX_done1_eventually;
  @(posedge clk) disable iff(reset)
  ##[0:$] $rose(done[M1]);
endproperty
fpv_pXX_done1_eventually: assume property (pXX_done1_eventually) else $error("[pXX_done1_eventually] does not hold");

//ID XXX: R#XX eventually will trigger done2
property pXX_done2_eventually;
  @(posedge clk) disable iff(reset)
  ##[0:$] $rose(done[M2]);
endproperty
fpv_pXX_done2_eventually: assume property (pXX_done2_eventually) else $error("[pXX_done2_eventually] does not hold");

//ID XXX: R#XX eventually will trigger done3
property pXX_done3_eventually;
  @(posedge clk) disable iff(reset)
  ##[0:$] $rose(done[M3]);
endproperty
fpv_pXX_done3_eventually: assume property (pXX_done3_eventually) else $error("[pXX_done3_eventually] does not hold");

//ID 38: R#15 when module1 releases memory, assert its done line
property p15_m1_done_when_release;
  @(posedge clk) disable iff(reset)
  ((accmodule == 1) ##1 (accmodule != 1)) |->
  (done[M1] == 1);
endproperty
fpv_p15_m1_done_when_release: cover property (p15_m1_done_when_release) else $error("[p15_m1_done_when_release] does not hold");

//ID 39: R#15 when module2 releases memory, assert its done line
property p15_m2_done_when_release;
  @(posedge clk) disable iff(reset)
  ((accmodule == 2) ##1 (accmodule != 2)) |->
  (done[M2] == 1);
endproperty
fpv_p15_m2_done_when_release: cover property (p15_m2_done_when_release) else $error("[p15_m2_done_when_release] does not hold");

//ID 40: R#15 when module3 releases memory, assert its done line
property p15_m3_done_when_release;
  @(posedge clk) disable iff(reset)
  ((accmodule == 3) ##1 (accmodule != 3)) |->
  (done[M3] == 1);
endproperty
fpv_p15_m3_done_when_release: cover property (p15_m3_done_when_release) else $error("[p15_m3_done_when_release] does not hold");

//ID XXX: R#XX eventually will trigger req2 & req3
property pXX_req2_and_req3_eventually;
  @(posedge clk) disable iff(reset)
  ##[0:$] (req[M2] && req[M3]);
endproperty
fpv_pXX_req2_and_req3_eventually: assume property (pXX_req2_and_req3_eventually) else $error("[pXX_req2_and_req3_eventually] does not hold");

//ID 26: R#12 simultaneous M2 and M3 alternate
property p12_when_together_alternate;
  @(posedge clk) disable iff(reset)
    (((!req[M1] && req[M2] && req[M3]) ##1 (accmodule == 2)) |->
    ##[0:$] ((!req[M1] && req[M2] && req[M3]) and (accmodule != 3) and (accmodule != 1)) |=> (accmodule == 3)) or
    (((!req[M1] && req[M2] && req[M3]) ##1 (accmodule == 3)) |->
    ##[0:$] ((!req[M1] && req[M2] && req[M3]) and (accmodule != 2) and (accmodule != 1)) |=> (accmodule == 2));
endproperty
fpv_p12_when_together_alternate: assert property (p12_when_together_alternate) else $error("[p12_when_together_alternate] does not hold");

//ID 45: R#18 Cycle limit for M1, M2 and M3
// already satisfied by other properties
// see properties: 
//                  ##ID 28.a & 29.a; R#13 M2 and M3 have two-cycle limit; [fb_M2_cycle_limit] M2 and M3 have two-cycle limit;
//                  ##ID 28.b & 29.b; R#13 M2 and M3 have two-cycle limit; [fb_M3_cycle_limit] M2 and M3 have two-cycle limit;
//                  ##ID 15.a & 68.a: R#9 if M1 interrupts M2, it can only hold memory for 2 clk cycles.
//                  ##ID 15.b & 68.b: R#9 if M1 interrupts M3, it can only hold memory for 2 clk cycles.
//                  ##ID 17: R#9 if M1 did not interrupt, can hold memory indefinitely

endmodule
//`endif
