#ifndef TRADESIGNAL_MQH
#define TRADESIGNAL_MQH

#include "MacdMarketStructure.mqh"
#include "LiquidityCycle.mqh"
#include "PremiumDiscount.mqh"
#include "OrderBlock.mqh"
#include "FairValueGap.mqh"
#include "BarData.mqh"
#include "Enums.mqh"

struct TradeSetup {
   SignalType signal;
   double     entryPrice;
   double     stopLoss;
   double     takeProfit;
   int        obIndex;
   bool       hasFVGConfirm;
   string     description;
};

class TradeSignal {

private:
   MacdMarketStructureClass* macdMS;
   LiquidityCycle*           liquidityCycle;
   PremiumDiscount*          premiumDiscount;
   OrderBlock*               orderBlock;
   FairValueGap*             fvg;
   BarData*                  barData;

   TradeSetup lastSetup;

   bool checkFVGOverlap(Trend trend, double obLow, double obHigh) {
      int count = fvg.getFVGCount();
      for (int i = 0; i < count; i++) {
         FVGZone zone;
         if (!fvg.getFVGZone(i, zone)) continue;
         if (zone.isMitigated)        continue;
         if (zone.trend != trend)     continue;
         if (zone.upper >= obLow && zone.lower <= obHigh)
            return true;
      }
      return false;
   }

   bool checkBullishConfluence(TradeSetup &setup) {
      if (macdMS.getLatestTrend() != TREND_BULLISH)
         return false;

      LiquidityState buyState = liquidityCycle.getBuyersState();
      if (buyState != LIQ_CLEAN && buyState != LIQ_RALLYE)
         return false;

      if (!premiumDiscount.canBuy())
         return false;

      if (!orderBlock.hasActiveBullishOB())
         return false;

      OBZone ob = orderBlock.getBullishOB(0);
      setup.signal      = SIGNAL_BUY;
      setup.entryPrice  = (ob.low + ob.high) / 2.0;
      setup.stopLoss    = ob.low - 2.0 * _Point;
      setup.takeProfit  = macdMS.getPrevMajorHighPrice();
      setup.obIndex     = ob.index;
      setup.hasFVGConfirm = checkFVGOverlap(TREND_BULLISH, ob.low, ob.high);
      setup.description = "BUY confluence confirmed";
      return true;
   }

   bool checkBearishConfluence(TradeSetup &setup) {
      if (macdMS.getLatestTrend() != TREND_BEARISH)
         return false;

      LiquidityState sellState = liquidityCycle.getSellersState();
      if (sellState != LIQ_CLEAN && sellState != LIQ_RALLYE)
         return false;

      if (!premiumDiscount.canSell())
         return false;

      if (!orderBlock.hasActiveBearishOB())
         return false;

      OBZone ob = orderBlock.getBearishOB(0);
      setup.signal      = SIGNAL_SELL;
      setup.entryPrice  = (ob.low + ob.high) / 2.0;
      setup.stopLoss    = ob.high + 2.0 * _Point;
      setup.takeProfit  = macdMS.getPrevMajorLowPrice();
      setup.obIndex     = ob.index;
      setup.hasFVGConfirm = checkFVGOverlap(TREND_BEARISH, ob.low, ob.high);
      setup.description = "SELL confluence confirmed";
      return true;
   }

public:
   TradeSignal() {
      macdMS         = NULL;
      liquidityCycle = NULL;
      premiumDiscount = NULL;
      orderBlock     = NULL;
      fvg            = NULL;
      barData        = NULL;

      lastSetup.signal       = SIGNAL_NONE;
      lastSetup.entryPrice   = 0;
      lastSetup.stopLoss     = 0;
      lastSetup.takeProfit   = 0;
      lastSetup.obIndex      = -1;
      lastSetup.hasFVGConfirm = false;
      lastSetup.description  = "";
   }

   void Init(MacdMarketStructureClass* ms, LiquidityCycle* lc, PremiumDiscount* pd,
             OrderBlock* ob, FairValueGap* fvgInstance, BarData* bd) {
      macdMS          = ms;
      liquidityCycle  = lc;
      premiumDiscount = pd;
      orderBlock      = ob;
      fvg             = fvgInstance;
      barData         = bd;
   }

   void update(int index, int totalBars) {
      if (index < totalBars - 1) return;

      TradeSetup setup;
      setup.signal       = SIGNAL_NONE;
      setup.entryPrice   = 0;
      setup.stopLoss     = 0;
      setup.takeProfit   = 0;
      setup.obIndex      = -1;
      setup.hasFVGConfirm = false;
      setup.description  = "";

      if (!checkBullishConfluence(setup))
         checkBearishConfluence(setup);

      lastSetup = setup;
   }

   TradeSetup getLastSetup() {
      return lastSetup;
   }

   bool hasActiveSignal() {
      return lastSetup.signal != SIGNAL_NONE;
   }

   string getSignalAsString() {
      string signalStr;
      switch (lastSetup.signal) {
         case SIGNAL_BUY:  signalStr = "BUY";  break;
         case SIGNAL_SELL: signalStr = "SELL"; break;
         default:          signalStr = "NONE"; break;
      }
      return StringFormat(
         "Signal : %s\nEntry  : %.5f\nSL     : %.5f\nTP     : %.5f\nFVG OK : %s",
         signalStr,
         lastSetup.entryPrice,
         lastSetup.stopLoss,
         lastSetup.takeProfit,
         lastSetup.hasFVGConfirm ? "YES" : "NO"
      );
   }

}

#endif
