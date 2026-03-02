#ifndef FAIRVALUEGAP_MQH
#define FAIRVALUEGAP_MQH

#include "Enums.mqh"
#include "BarData.mqh"

struct FVGZone {
   int    candleIndex;
   double upper;
   double lower;
   double midpoint;
   Trend  trend;
   bool   isMitigated;
};

class FairValueGap {

private:
   BarData*  barData;
   FVGZone   zones[];
   int       count;

   void checkMitigation(int currentIndex) {
      for(int i = 0; i < count; i++) {
         if(zones[i].isMitigated) continue;
         if(zones[i].trend == TREND_BULLISH) {
            if(barData.GetLow(currentIndex) <= zones[i].lower)
               zones[i].isMitigated = true;
         } else {
            if(barData.GetHigh(currentIndex) >= zones[i].upper)
               zones[i].isMitigated = true;
         }
      }
   }

   bool zoneExists(int candleIndex, Trend trend) {
      for(int i = 0; i < count; i++) {
         if(zones[i].candleIndex == candleIndex && zones[i].trend == trend)
            return true;
      }
      return false;
   }

   void addZone(FVGZone &zone) {
      ArrayResize(zones, count + 1);
      zones[count] = zone;
      count++;
   }

public:
   void Init(BarData* barDataInstance) {
      barData = barDataInstance;
      count = 0;
      ArrayResize(zones, 0);
   }

   void update(int index, int total) {
      if(index < 2 || index >= total) return;

      int first  = index - 2;
      int second = index - 1;
      int third  = index;

      double firstHigh  = barData.GetHigh(first);
      double firstLow   = barData.GetLow(first);
      double thirdHigh  = barData.GetHigh(third);
      double thirdLow   = barData.GetLow(third);

      // Bullish FVG: gap between high of first candle and low of third candle
      if(thirdLow > firstHigh && !zoneExists(second, TREND_BULLISH)) {
         FVGZone z;
         z.candleIndex = second;
         z.upper       = thirdLow;
         z.lower       = firstHigh;
         z.midpoint    = (z.upper + z.lower) / 2.0;
         z.trend       = TREND_BULLISH;
         z.isMitigated = false;
         addZone(z);
      }

      // Bearish FVG: gap between low of first candle and high of third candle
      if(thirdHigh < firstLow && !zoneExists(second, TREND_BEARISH)) {
         FVGZone z;
         z.candleIndex = second;
         z.upper       = firstLow;
         z.lower       = thirdHigh;
         z.midpoint    = (z.upper + z.lower) / 2.0;
         z.trend       = TREND_BEARISH;
         z.isMitigated = false;
         addZone(z);
      }

      checkMitigation(index);
   }

   int getFVGCount() {
      return count;
   }

   bool getFVGZone(int idx, FVGZone &zone) {
      if(idx < 0 || idx >= count) return false;
      zone = zones[idx];
      return true;
   }

   bool getLatestBullishFVG(FVGZone &zone) {
      for(int i = count - 1; i >= 0; i--) {
         if(zones[i].trend == TREND_BULLISH) {
            zone = zones[i];
            return true;
         }
      }
      return false;
   }

   bool getLatestBearishFVG(FVGZone &zone) {
      for(int i = count - 1; i >= 0; i--) {
         if(zones[i].trend == TREND_BEARISH) {
            zone = zones[i];
            return true;
         }
      }
      return false;
   }
};

#endif