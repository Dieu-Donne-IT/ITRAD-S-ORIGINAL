#ifndef FAIRVALUEGAP_MQH
#define FAIRVALUEGAP_MQH

#include "BarData.mqh"
#include "Enums.mqh"

struct FVGZone {
   int    candleIndex;
   double upper;
   double lower;
   double midpoint;
   Trend  trend;
   bool   isMitigated;
};

class FairValueGap{

private:
   BarData*  barData;
   FVGZone   fvgZones[];
   int       fvgCount;
   int       lastCalculatedIndex;
   static const int MAX_FVG = 50;

   bool detectBullishFVG(int i, FVGZone &zone){
      double firstCandleHigh = barData.GetHigh(i - 2);
      double thirdCandleLow  = barData.GetLow(i);
      if(thirdCandleLow > firstCandleHigh){
         zone.candleIndex  = i - 1;
         zone.upper        = thirdCandleLow;
         zone.lower        = firstCandleHigh;
         zone.midpoint     = (zone.upper + zone.lower) / 2.0;
         zone.trend        = TREND_BULLISH;
         zone.isMitigated  = false;
         return true;
      }
      return false;
   }

   bool detectBearishFVG(int i, FVGZone &zone){
      double firstCandleLow   = barData.GetLow(i - 2);
      double thirdCandleHigh  = barData.GetHigh(i);
      if(thirdCandleHigh < firstCandleLow){
         zone.candleIndex  = i - 1;
         zone.upper        = firstCandleLow;
         zone.lower        = thirdCandleHigh;
         zone.midpoint     = (zone.upper + zone.lower) / 2.0;
         zone.trend        = TREND_BEARISH;
         zone.isMitigated  = false;
         return true;
      }
      return false;
   }

   void checkMitigation(int currentIndex){
      for(int k = 0; k < fvgCount; k++){
         if(fvgZones[k].isMitigated) continue;
         if(fvgZones[k].trend == TREND_BULLISH){
            if(barData.GetLow(currentIndex) <= fvgZones[k].midpoint)
               fvgZones[k].isMitigated = true;
         } else {
            if(barData.GetHigh(currentIndex) >= fvgZones[k].midpoint)
               fvgZones[k].isMitigated = true;
         }
      }
   }

   void addFVG(FVGZone &zone){
      if(fvgCount < MAX_FVG){
         fvgZones[fvgCount] = zone;
         fvgCount++;
      }
   }

public:
   FairValueGap(){
      fvgCount            = 0;
      lastCalculatedIndex = -1;
      ArrayResize(fvgZones, MAX_FVG);
   }

   void Init(BarData* barDataInstance){
      barData = barDataInstance;
   }

   void update(int index, int totalBars){
      if(index < 2) return;
      if(index == lastCalculatedIndex) return;

      checkMitigation(index);

      FVGZone bullishZone;
      FVGZone bearishZone;
      if(detectBullishFVG(index, bullishZone)) addFVG(bullishZone);
      if(detectBearishFVG(index, bearishZone)) addFVG(bearishZone);

      lastCalculatedIndex = index;
   }

   int getFVGCount(){
      return fvgCount;
   }

   bool getFVGZone(int idx, FVGZone &zone){
      if(idx < 0 || idx >= fvgCount) return false;
      zone = fvgZones[idx];
      return true;
   }

   bool getLatestBullishFVG(FVGZone &zone){
      for(int i = fvgCount - 1; i >= 0; i--){
         if(fvgZones[i].trend == TREND_BULLISH && !fvgZones[i].isMitigated){
            zone = fvgZones[i];
            return true;
         }
      }
      return false;
   }

   bool getLatestBearishFVG(FVGZone &zone){
      for(int i = fvgCount - 1; i >= 0; i--){
         if(fvgZones[i].trend == TREND_BEARISH && !fvgZones[i].isMitigated){
            zone = fvgZones[i];
            return true;
         }
      }
      return false;
   }

   bool isInBullishFVG(double price){
      for(int i = 0; i < fvgCount; i++){
         if(fvgZones[i].trend == TREND_BULLISH && !fvgZones[i].isMitigated){
            if(price >= fvgZones[i].lower && price <= fvgZones[i].upper)
               return true;
         }
      }
      return false;
   }

   bool isInBearishFVG(double price){
      for(int i = 0; i < fvgCount; i++){
         if(fvgZones[i].trend == TREND_BEARISH && !fvgZones[i].isMitigated){
            if(price >= fvgZones[i].lower && price <= fvgZones[i].upper)
               return true;
         }
      }
      return false;
   }

}

#endif