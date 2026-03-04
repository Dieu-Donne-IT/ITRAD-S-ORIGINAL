#ifndef ORDERBLOCKDRAWING_MQH
#define ORDERBLOCKDRAWING_MQH

#include "OrderBlock.mqh"
#include "BarData.mqh"
#include "DrawingUtils.mqh"

class OrderBlockDrawing {
private:
   OrderBlock* ob;
   BarData* barData;
   int lastBullishCount;
   int lastBearishCount;
   string PREFIX_BULL;
   string PREFIX_BEAR;
   int totalBars;

   void drawBullishOBs() {
      DrawingUtils::DeleteObjectsByPrefix(PREFIX_BULL);
      for(int i = 0; i < ob.getBullishOBCount(); i++) {
         OrderBlockData zone = ob.getBullishOB(i);
         datetime timeStart = barData.GetTime(zone.index);
         datetime timeEnd   = barData.GetTime(totalBars - 1);
         color zoneColor = zone.isMitigated ? clrDarkGreen : clrLimeGreen;
         string name = PREFIX_BULL + IntegerToString(i);
         DrawingUtils::DrawRectangle(name, timeStart, zone.high, timeEnd, zone.low, zoneColor);
      }
   }

   void drawBearishOBs() {
      DrawingUtils::DeleteObjectsByPrefix(PREFIX_BEAR);
      for(int i = 0; i < ob.getBearishOBCount(); i++) {
         OrderBlockData zone = ob.getBearishOB(i);
         datetime timeStart = barData.GetTime(zone.index);
         datetime timeEnd   = barData.GetTime(totalBars - 1);
         color zoneColor = zone.isMitigated ? clrDarkRed : clrOrangeRed;
         string name = PREFIX_BEAR + IntegerToString(i);
         DrawingUtils::DrawRectangle(name, timeStart, zone.high, timeEnd, zone.low, zoneColor);
      }
   }

public:
   OrderBlockDrawing() {
      lastBullishCount = 0;
      lastBearishCount = 0;
      PREFIX_BULL = "SMV_OB_BULL_";
      PREFIX_BEAR = "SMV_OB_BEAR_";
   }

   void Init(OrderBlock* obInstance, BarData* barDataInstance) {
      ob = obInstance;
      barData = barDataInstance;
   }

   void update(int index, int total) {
      totalBars = total;
      if(ob.getBullishOBCount() != lastBullishCount) {
         drawBullishOBs();
         lastBullishCount = ob.getBullishOBCount();
      }
      if(ob.getBearishOBCount() != lastBearishCount) {
         drawBearishOBs();
         lastBearishCount = ob.getBearishOBCount();
      }
   }

   void OnDeinit() {
      DrawingUtils::DeleteObjectsByPrefix(PREFIX_BULL);
      DrawingUtils::DeleteObjectsByPrefix(PREFIX_BEAR);
   }
};

#endif
