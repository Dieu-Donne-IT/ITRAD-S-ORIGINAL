#ifndef LIQUIDITYCYCLE_MQH
#define LIQUIDITYCYCLE_MQH

#include "Enums.mqh"

class LiquidityCycle {

public:
   LiquidityCycle() {}

   void Init() {}

   void update(int index, int totalBars) {}

   LiquidityState getBuyersState()  { return LIQ_CLEAN; }
   LiquidityState getSellersState() { return LIQ_CLEAN; }

   string getBuyersStateAsString() {
      switch(getBuyersState()) {
         case LIQ_CLEAN:  return "Clean";
         case LIQ_RALLYE: return "Rallye";
         default:         return "None";
      }
   }

   string getSellersStateAsString() {
      switch(getSellersState()) {
         case LIQ_CLEAN:  return "Clean";
         case LIQ_RALLYE: return "Rallye";
         default:         return "None";
      }
   }

}

#endif
