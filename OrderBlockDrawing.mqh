#ifndef ORDERBLOCKDRAWING_MQH
#define ORDERBLOCKDRAWING_MQH

#include "OrderBlock.mqh"

class OrderBlockDrawing {
private:
   OrderBlock* ob;
   BarData* barData;
   int lastBullishCount;
   int lastBearishCount;

   void clearAllOBObjects() {
      int total = ObjectsTotal(0);
      for(int i = total - 1; i >= 0; i--) {
         string name = ObjectName(0, i);
         if(StringFind(name, "SMV_OB_BULL_") == 0 || StringFind(name, "SMV_OB_BEAR_") == 0) {
            ObjectDelete(0, name);
         }
      }
   }

   void drawOBRect(string name, datetime startTime, datetime endTime, double high, double low, color clr, bool isMitigated) {
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);

      ObjectCreate(0, name, OBJ_RECTANGLE, 0, startTime, high, endTime, low);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      if(isMitigated) {
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
      } else {
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      }
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   }

   void drawBullishOBs(int index) {
      for(int i = 0; i < ob.getBullishOBCount(); i++) {
         OrderBlockData obData = ob.getBullishOB(i);
         string name = "SMV_OB_BULL_" + IntegerToString(i);
         datetime startTime = barData.GetTime(obData.index);
         datetime endTime   = barData.GetTime(index);
         drawOBRect(name, startTime, endTime, obData.high, obData.low, clrGreen, obData.isMitigated);
      }
   }

   void drawBearishOBs(int index) {
      for(int i = 0; i < ob.getBearishOBCount(); i++) {
         OrderBlockData obData = ob.getBearishOB(i);
         string name = "SMV_OB_BEAR_" + IntegerToString(i);
         datetime startTime = barData.GetTime(obData.index);
         datetime endTime   = barData.GetTime(index);
         drawOBRect(name, startTime, endTime, obData.high, obData.low, clrRed, obData.isMitigated);
      }
   }

public:
   void Init(OrderBlock* obInstance, BarData* barDataInstance) {
      ob = obInstance;
      barData = barDataInstance;
      lastBullishCount = -1;
      lastBearishCount = -1;
   }

   void update(int index, int totalBars) {
      if(index >= totalBars - 1) return;

      int bullCount = ob.getBullishOBCount();
      int bearCount = ob.getBearishOBCount();

      if(bullCount != lastBullishCount || bearCount != lastBearishCount) {
         clearAllOBObjects();
         drawBullishOBs(index);
         drawBearishOBs(index);
         lastBullishCount = bullCount;
         lastBearishCount = bearCount;
      }
   }
};

#endif
