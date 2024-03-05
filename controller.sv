`include "properties.sv"

// Code your design here
module controller(
  input clk,
  input reset,
  input [2:0] req,
  input [2:0] done,
  output logic [4:0] mstate, // 1-hot encoded
  output logic [1:0] accmodule,
  output integer nb_interrupts  // nb of interruptions
);


  logic [17:0] ns, ps;
  
  parameter M1 = 0;
  parameter M2 = 1;
  parameter M3 = 2;

  enum {
    // The state is 1-hot encoded, these enums indicate which bit corresponds to which state being active.
   
    IDLE_2p = 0, // Idle with M2 priority in case of contention
    IDLE_3p = 1, // Idle with M3 priority
    
    M1in_2p = 2, // M1 first to use memory
    M1in_3p = 3,
    M2in_2p = 4, // M2 first to use memory
    M2in_3p = 5,
    M3in_2p = 6, // M3 first to use memory
    M3in_3p = 7,
    
    M1it_2p = 8, // M1 using memory after an interruption
    M1it_3p = 9,
    
    M1id_2p = 10, // M1 using memory indefinitely
    M1id_3p = 11,
    M1sd_2p = 12, // M1 using memory second cycle
    M1sd_3p = 13,
    M2sd_2p = 14, // M2 using memory second cycle [Boli Modified value from 13->14 to compile]
    M2sd_3p = 15,
    M3sd_2p = 16, // M3 using memory second cycle
    M3sd_3p = 17
  } index;
  

  // Reset, including returning to IDLE state, otherwise update state
  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      ps          <= '0;      
      ps[IDLE_2p] <= 1'b0; //arbitrary: M2 has priority at next contention
      nb_interrupts <= 0;      
    end
    else if(ns[M1it_2p] || ns[M1it_3p]) begin
      ps <= ns;
      nb_interrupts <= nb_interrupts + 1;
    end
    else begin
      ps <= ns;
    end
  end
  

  // Next state and output logic
  always_comb begin
    // Set outputs to initial values
    mstate = 0;
    accmodule = 2'b00;
    ns = '0;

    unique case(1'b1)
      
      ps[IDLE_2p]: begin
        casez(req)
          3'b??1: ns[M1in_2p] = 1'b1;
          3'b010: ns[M2in_2p] = 1'b1;
          3'b110: ns[M2in_3p] = 1'b1;
          3'b100: ns[M3in_2p] = 1'b1;
          default: ns[IDLE_2p] = 1'b1; //Default used instead of 3'b000 to cover branch coverage [Code coverage]
        endcase
        mstate = 5'b00000;
        accmodule = 2'b00;
      end
      
      ps[M1in_2p]: begin
        if(done[M1]) begin
          casez(req)
            //3'b??1: ns[M1in_2p] = 1'b1;
            3'b01?: ns[M2in_2p] = 1'b1; 
            3'b10?: ns[M3in_2p] = 1'b1;
            3'b11?: ns[M2in_3p] = 1'b1;  
            //3'b100: ns[M3in_2p] = 1'b1;
            default: ns[IDLE_2p] = 1'b1;
          endcase
        end
        else ns[M1id_2p] = 1'b1;
        mstate = 5'b00010;
        accmodule = 2'b01;
      end
      
      ps[M2in_2p]: begin
        if(done[M2]) begin
          casez(req)
            3'b??1: ns[M1in_2p] = 1'b1;
            //3'b010: ns[M2in_2p] = 1'b1;  REQ16 fail memory hogging
            //3'b110: ns[M2in_3p] = 1'b1;  REQ16 fail memory hogging
            3'b100: ns[M3in_2p] = 1'b1;
            default: ns[IDLE_2p] = 1'b1;
          endcase
        end
        else begin
          if(req[M1]) begin
            ns[M1it_2p] = 1'b1;
          end
          else        ns[M2sd_2p] = 1'b1;
        end
        mstate = 5'b00100;
        accmodule = 2'b10;
      end
      
      ps[M3in_2p]: begin
        if(done[M3]) begin
          casez(req)
            3'b??1: ns[M1in_2p] = 1'b1;
            3'b010: ns[M2in_2p] = 1'b1;
            //3'b110: ns[M2in_3p] = 1'b1;  REQ16 fail memory hogging
            //3'b100: ns[M3in_2p] = 1'b1;  REQ16 fail memory hogging
            default: ns[IDLE_2p] = 1'b1;   //Default used instead of 3'b000 to cover branch coverage [Code coverage]
          endcase
        end
        
        else begin
          if(req[M1]) begin
            ns[M1it_2p] = 1'b1;
            //nb_interrupts = nb_interrupts+1; Delete candidate
          end
          else       ns[M3sd_2p] = 1'b1;
        end
        mstate = 5'b00110;
        accmodule = 2'b11;
      end
      
      ps[M1it_2p]: begin
        if(done[M1]) begin
          casez(req)
            //3'b??1: ns[M1in_2p] = 1'b1;  REQ16 fail memory hogging  
            3'b010: ns[M2in_2p] = 1'b1;
            3'b110: ns[M2in_3p] = 1'b1;
            3'b100: ns[M3in_2p] = 1'b1;
            default: ns[IDLE_2p] = 1'b1;    //Default used instead of 3'b000 to cover branch coverage [Code coverage]
          endcase
        end
        else        ns[M1sd_2p] = 1'b1;
        mstate = 5'b01000;
        accmodule = 2'b01;
      end
      
      ps[M1id_2p]: begin
        if(done[M1]) begin
          casez(req)
            //3'b??1: ns[M1in_2p] = 1'b1; REQ16 fail memory hogging 
            3'b010: ns[M2in_2p] = 1'b1;
            3'b110: ns[M2in_3p] = 1'b1;
            3'b100: ns[M3in_2p] = 1'b1;
            default: ns[IDLE_2p] = 1'b1;    //Default used instead of 3'b000 to cover branch coverage [Code coverage]
          endcase
        end
        else        ns[M1id_2p] = 1'b1;
        mstate = 5'b01010;
        accmodule = 2'b01;
      end
      
      ps[M1sd_2p]: begin
        casez(req)
          //3'b??1: ns[M1in_2p] = 1'b1;    Memory hogging
          3'b01?: ns[M2in_2p] = 1'b1;
          3'b11?: ns[M2in_3p] = 1'b1;
          3'b10?: ns[M3in_2p] = 1'b1;
          default: ns[IDLE_2p] = 1'b1;    //Default used instead of 3'b000 to cover branch coverage [Code coverage]
        endcase
        mstate = 5'b01100;
        accmodule = 2'b01;
      end
      
      //M2 in its second cycle of using the memory
      ps[M2sd_2p]: begin
        casez(req)
          3'b??1: ns[M1in_2p] = 1'b1;
          //3'b010: ns[M2in_2p] = 1'b1;   Not possible to Retrigger
          //3'b110: ns[M2in_3p] = 1'b1;   Not possible to Retrigger
          3'b1?0: ns[M3in_2p] = 1'b1;
          default: ns[IDLE_2p] = 1'b1;     //Default used instead of 3'b000 to cover branch coverage [Code coverage]
        endcase
        mstate = 5'b01110;
        accmodule = 2'b10;
      end
      
      //M3 in its second cycle of using the memory
      ps[M3sd_2p]: begin
        casez(req)
          3'b??1: ns[M1in_2p] = 1'b1;
          3'b?10: ns[M2in_2p] = 1'b1;
          //3'b110: ns[M2in_3p] = 1'b1;      REQ16 fail memory hogging
          //3'b100: ns[M3in_2p] = 1'b1;        REQ16 fail memory hogging
          default: ns[IDLE_2p] = 1'b1;      //Default used instead of 3'b000 to cover branch coverage [Code coverage]
        endcase
        mstate = 5'b10000;
        accmodule = 2'b11;
      end
      
      ps[IDLE_3p]: begin
        casez(req)
          3'b??1: ns[M1in_3p] = 1'b1;
          3'b010: ns[M2in_3p] = 1'b1;
          3'b110: ns[M3in_2p] = 1'b1;
          3'b100: ns[M3in_3p] = 1'b1;
          default: ns[IDLE_3p] = 1'b1;      //Default used instead of 3'b000 to cover branch coverage [Code coverage]
        endcase
        mstate = 5'b00001;
        accmodule = 2'b00;
      end
      
      ps[M1in_3p]: begin
        if(done[M1]) begin
          casez(req)
            //3'b??1: ns[M1in_2p] = 1'b1;
            3'b01?: ns[M2in_3p] = 1'b1; 
            3'b10?: ns[M3in_3p] = 1'b1;
            3'b11?: ns[M3in_2p] = 1'b1;  
            //3'b100: ns[M3in_3p] = 1'b1;
            default: ns[IDLE_3p] = 1'b1;
          endcase
        end
        else ns[M1id_3p] = 1'b1;           
        mstate = 5'b00011;
        accmodule = 2'b01;
      end
      
      ps[M2in_3p]: begin
        if(done[M2]) begin
          casez(req)
            3'b??1: ns[M1in_3p] = 1'b1;
            //3'b010: ns[M2in_3p] = 1'b1;  REQ16 fail memory hogging
            //3'b110: ns[M3in_2p] = 1'b1;  REQ16 fail memory hogging
            3'b100: ns[M3in_3p] = 1'b1;
            default: ns[IDLE_3p] = 1'b1;    //Default used instead of 3'b000 to cover branch coverage [Code coverage]
          endcase
        end
        else begin
          if(req[M1]) begin 
            ns[M1it_3p] = 1'b1;
            //nb_interrupts = nb_interrupts+1; Delete candidate
          end
          else        ns[M2sd_3p] = 1'b1;
        end
        mstate = 5'b00101;
        accmodule = 2'b10;
      end
      
      ps[M3in_3p]: begin
        if(done[M3]) begin
          casez(req)
            3'b??1: ns[M1in_3p] = 1'b1;
            3'b010: ns[M2in_3p] = 1'b1;
            //3'b110: ns[M3in_2p] = 1'b1;  REQ16 fail memory hogging
            //3'b100: ns[M3in_3p] = 1'b1;  REQ16 fail memory hogging
            default: ns[IDLE_3p] = 1'b1;    //Default used instead of 3'b000 to cover branch coverage [Code coverage]
          endcase
        end
        else begin
          if(req[M1]) begin
            ns[M1it_3p] = 1'b1;
            //nb_interrupts = nb_interrupts+1;  Delete candidate
          end
          else        ns[M3sd_3p] = 1'b1;
        end
        mstate = 5'b00111;
        accmodule = 2'b11;
      end
      
      ps[M1it_3p]: begin
        if(done[M1]) begin
          casez(req)
            //3'b001: ns[M1in_3p] = 1'b1;  REQ16 fail memory hogging
            3'b010: ns[M2in_3p] = 1'b1;
            3'b110: ns[M3in_2p] = 1'b1;
            3'b100: ns[M3in_3p] = 1'b1;
            default: ns[IDLE_3p] = 1'b1;    //Default used instead of 3'b000 to cover branch coverage [Code coverage]
          endcase
        end
        else        ns[M1sd_3p] = 1'b1;
        mstate = 5'b01001;
        accmodule = 2'b01;
      end
      
      ps[M1id_3p]: begin
        if(done[M1]) begin
          casez(req)
            //3'b??1: ns[M1in_3p] = 1'b1;  REQ16 fail memory hogging
            3'b010: ns[M2in_3p] = 1'b1;
            3'b110: ns[M3in_2p] = 1'b1;
            3'b100: ns[M3in_3p] = 1'b1;
            default: ns[IDLE_3p] = 1'b1;    //Default used instead of 3'b000 to cover branch coverage [Code coverage]
          endcase
        end
        else        ns[M1id_3p] = 1'b1;
        mstate = 5'b01011;
        accmodule = 2'b01;
      end
      
      ps[M1sd_3p]: begin
        casez(req)
          //3'b??1: ns[M1in_3p] = 1'b1;    //Memory hogging
          3'b01?: ns[M2in_3p] = 1'b1;
          3'b11?: ns[M3in_2p] = 1'b1;
          3'b10?: ns[M3in_3p] = 1'b1;
          default: ns[IDLE_3p] = 1'b1;    //Default used instead of 3'b000 to cover branch coverage [Code coverage]
        endcase
        mstate = 5'b01101;
        accmodule = 2'b01;
      end
      
      ps[M2sd_3p]: begin
        casez(req)
          3'b??1: ns[M1in_3p] = 1'b1;
          //3'b010: ns[M2in_3p] = 1'b1;       retriggering after smooth ending [conflict with done and req]
          //3'b110: ns[M3in_2p] = 1'b1;     retriggering after smooth ending [conflict with done and req]
          3'b1?0: ns[M3in_3p] = 1'b1;
          default: ns[IDLE_3p] = 1'b1;    //Default used instead of 3'b000 to cover branch coverage [Code coverage]
        endcase
        mstate = 5'b01111;
        accmodule = 2'b10;
      end
      
      ps[M3sd_3p]: begin
        casez(req)
          3'b??1: ns[M1in_3p] = 1'b1;
          3'b?10: ns[M2in_3p] = 1'b1;
          //3'b110: ns[M3in_2p] = 1'b1;    retriggering after smooth ending [conflict with done and req]
          //3'b100: ns[M3in_3p] = 1'b1;      retriggering after smooth ending [conflict with done and req]
          default: ns[IDLE_3p] = 1'b1;    //Default used instead of 3'b000 to cover branch coverage [Code coverage]
        endcase
        mstate = 5'b10001;
        accmodule = 2'b11;
      end
      
      default: begin
        casez(req)
          3'b??1: ns[M1in_2p] = 1'b1;
          3'b010: ns[M2in_2p] = 1'b1;
          3'b110: ns[M2in_3p] = 1'b1;
          3'b100: ns[M3in_2p] = 1'b1;
          default: ns[IDLE_2p] = 1'b1;    //Default used instead of 3'b000 to cover branch coverage [Code coverage]
        endcase
        mstate = 5'b00000;
        accmodule = 2'b00;
      end
    endcase
    
  end



endmodule

bind controller controller_assertions sva_fpv(.*);


