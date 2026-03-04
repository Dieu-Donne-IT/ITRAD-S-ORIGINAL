#ifndef FVGDRAWER_MQH
#define FVGDRAWER_MQH

#include "FairValueGap.mqh"
#include "BarData.mqh"
#include "DrawingUtils.mqh"

class FVGDrawer {
private:
   FairValueGap* fvg;
   BarData*      barData;
   int           lastDrawnCount;
   string        PREFIX_BULL;
   string        PREFIX_BEAR;
   int           totalBars;

public:
   FVGDrawer() {
      lastDrawnCount = 0;
      PREFIX_BULL    = "SMC_FVG_BULL_";
      PREFIX_BEAR    = "SMC_FVG_BEAR_";
   }

   void Init(FairValueGap* fvgInstance, BarData* barDataInstance) {
      fvg     = fvgInstance;
      barData = barDataInstance;
   }

   void update(int index, int total) {
      totalBars = total;
      if(fvg.getFVGCount() == lastDrawnCount) return;
      redrawAll();
      lastDrawnCount = fvg.getFVGCount();
   }

   void redrawAll() {
      DrawingUtils::DeleteObjectsByPrefix(PREFIX_BULL);
      DrawingUtils::DeleteObjectsByPrefix(PREFIX_BEAR);

      for(int i = 0; i < fvg.getFVGCount(); i++) {
         FVGZone zone;
         if(!fvg.getFVGZone(i, zone)) continue;

         datetime timeStart = barData.GetTime(zone.candleIndex);
         datetime timeEnd   = barData.GetTime(totalBars - 1);

         color  zoneColor;
         string prefix;
         if(zone.trend == TREND_BULLISH) {
            zoneColor = zone.isMitigated ? clrDarkGreen : clrLimeGreen;
            prefix    = PREFIX_BULL;
         } else {
            zoneColor = zone.isMitigated ? clrDarkRed : clrOrangeRed;
            prefix    = PREFIX_BEAR;
         }

         string name = prefix + IntegerToString(i);
         DrawingUtils::DrawRectangle(name, timeStart, zone.upper, timeEnd, zone.lower, zoneColor);
      }
   }

   void OnDeinit() {
      DrawingUtils::DeleteObjectsByPrefix(PREFIX_BULL);
      DrawingUtils::DeleteObjectsByPrefix(PREFIX_BEAR);
   }
};

#endif
