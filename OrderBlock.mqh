#ifndef ORDERBLOCK_MQH
#define ORDERBLOCK_MQH

#include "Enums.mqh";
#include "BarData.mqh";
#include "MacdMarketStructure.mqh";
#include "Fractal.mqh";
#include "CandleBreakAnalyzerStatic.mqh";
#include "InsideBarClass.mqh";
#include "Fibonacci.mqh";

struct OrderBlockData {
   int    index;       // bar index of the OB candle
   double high;        // OB zone top
   double low;         // OB zone bottom (= open of OB candle for SMV)
   bool   isBullish;   // true = bullish OB (buy zone), false = bearish OB (sell zone)
   bool   isActive;    // false once price closes through the OB
   bool   isMitigated; // true once price entered the OB zone (partial fill)
};

class OrderBlock{

private:
   
   int index;
   bool isOrderBlockCalculated;
   BarData* barData;
   MacdMarketStructureClass* macdMarketStructure;
   FractalClass* fractal;
   InsideBarClass *insideBar;
   Fibonacci *fibonacci;
   
   int getMarketBreakAtIndex;

   OrderBlockData bullishOrderBlocks[];
   OrderBlockData bearishOrderBlocks[];
   int bullishOBCount;
   int bearishOBCount;
   
   struct InducementBand{
      double upperBand;
      double lowerBand;
   };
   
   void calcOrderBlock(){
      
      switch(macdMarketStructure.getLatestTrend()){
         case TREND_BULLISH:
            calcBullishOrderBlock();
            break;
         case TREND_BEARISH:
            calcBearishOrderBlock();
            break;
      };
      
      isOrderBlockCalculated = true;
   
   }
   
   void calcBullishOrderBlock(){
      int fractalFromRange[],result[],orderBlockIndices[];
      fractal.GetFractalFromRange(macdMarketStructure.getLatestMajorLowIndex(),macdMarketStructure.getInducementIndex()-1,false,fractalFromRange);
      
      int fractalRemoveCount = ArraySize(fractalFromRange);
      if (fractalRemoveCount == 0)
         return; // nothing to do
      
      double fiboLevel = fibonacci.fiboRetrace.getFiboLevel(0);
      
      for (int i = fractalRemoveCount - 1; i >= 0; i--) {
          int fractalIndex = fractalFromRange[i];
          double low = barData.GetLow(fractalIndex);
      
          if (low < fiboLevel) {
              ArrayRemove(fractalFromRange, i + 1);  // Keep elements 0..i
              break;
          }
      }
      

      
      int tmp[],orderBlockTmp[];
      ArrayResize(tmp, macdMarketStructure.getInducementIndex() - macdMarketStructure.getLatestMajorLowIndex()); // max possible size
      ArrayResize(orderBlockTmp, macdMarketStructure.getInducementIndex() - macdMarketStructure.getLatestMajorLowIndex()); // max possible size
      int count = 0,orderBlockCount = 0;
      
      for(int i = 0; i<ArraySize(fractalFromRange); i++){
      
         int getFractal = fractalFromRange[i];
         
         InducementBand inducementBand = getInducementBand(getFractal);
         
         bool isFractalSweep = checkBullishFractalSweep(getFractal,inducementBand);
         
         if(isFractalSweep){
         
            bool isFvg = false;
            
            isFvg = identifyFVG(TREND_BULLISH,getFractal,getFractal+1,getFractal+2);
            
            /*
            // mother bar fvg
            if(insideBar.GetMotherBar(getFractal) == 1){
               
               int findInsideBarCount = getFractal+1;
               while(findInsideBarCount < macdMarketStructure.getLatestMajorHighIndex()){
                  int result = insideBar.GetInsideBar(findInsideBarCount);
                  
                  if(result == 0){
                     isFvg = identifyFVG(TREND_BULLISH,getFractal,findInsideBarCount,findInsideBarCount+1);
                     break;
                  }
                  
                  findInsideBarCount++;
               }
               
            }else{
               isFvg = identifyFVG(TREND_BULLISH,getFractal,getFractal+1,getFractal+2);
            }
            //
            */
            
            // check is orderblock are taked
            int lowestLowIndex = barData.getLowestLowValueByRange(getFractal+3);
            double lowestLowPrice = barData.GetLow(lowestLowIndex);
            
            if(lowestLowPrice<=barData.GetHigh(getFractal)){
               continue;
            }
            
            //
            
            if(isFvg){
               orderBlockTmp[orderBlockCount++] = getFractal;
            }
         }
         
         
         if(isFractalSweep){
            tmp[count++] = getFractal;
         }

      }
      
      ArrayResize(result, count);
      for (int i = 0; i < count; i++){
         result[i] = tmp[i];
      }
      
      ArrayResize(orderBlockIndices, orderBlockCount);
      for (int i = 0; i < orderBlockCount; i++){
         orderBlockIndices[i] = orderBlockTmp[i];
      }
      
      /*
      for(int i = 0; i<ArraySize(result); i++){
         Print(i," : fractal sweep : ",barData.GetTime(result[i]));
      }
      */
      
      ArrayResize(bullishOrderBlocks, orderBlockCount);
      bullishOBCount = 0;
      for(int i = 0; i < orderBlockCount; i++){
         OrderBlockData ob;
         ob.index      = orderBlockIndices[i];
         ob.high       = barData.GetHigh(orderBlockIndices[i]);
         ob.low        = barData.GetOpen(orderBlockIndices[i]);
         ob.isBullish  = true;
         ob.isActive   = true;
         ob.isMitigated = false;
         bullishOrderBlocks[bullishOBCount++] = ob;
         Print(i," : orderblock : ",barData.GetTime(orderBlockIndices[i]));
      }
         
         
   }
   
   void calcBearishOrderBlock(){
      int fractalFromRange[],result[],orderBlockIndices[];
      fractal.GetFractalFromRange(macdMarketStructure.getLatestMajorHighIndex(),macdMarketStructure.getInducementIndex()-1,true,fractalFromRange);
      
      int fractalRemoveCount = ArraySize(fractalFromRange);
      if (fractalRemoveCount == 0)
         return; // nothing to do
      
      double fiboLevel = fibonacci.fiboRetrace.getFiboLevel(0);
      
      for (int i = fractalRemoveCount - 1; i >= 0; i--) {
         int fractalIndex = fractalFromRange[i];
         double high = barData.GetHigh(fractalIndex);
         if (high > fiboLevel) {
            ArrayRemove(fractalFromRange, i + 1);  // Keep elements 0..i
            break;
         }
      }
   

      int tmp[],orderBlockTmp[];
      ArrayResize(tmp, macdMarketStructure.getInducementIndex() - macdMarketStructure.getLatestMajorHighIndex()); // max possible size
      ArrayResize(orderBlockTmp, macdMarketStructure.getInducementIndex() - macdMarketStructure.getLatestMajorHighIndex()); // max possible size
      int count = 0, orderBlockCount = 0;
      
      for(int i = 0; i<ArraySize(fractalFromRange); i++){
         
         InducementBand inducementBand = getInducementBand(fractalFromRange[i]);
         
         bool isFractalSweep = checkBearishFractalSweep(fractalFromRange[i],inducementBand);
         
         if(isFractalSweep){
            int getFractal = fractalFromRange[i];

            bool isFvg = identifyFVG(TREND_BEARISH, getFractal, getFractal+1, getFractal+2);

            // check is orderblock are taked
            int highestHighIndex = barData.getHighestHighValueByRange(getFractal+3);
            double highestHighPrice = barData.GetHigh(highestHighIndex);

            if(highestHighPrice >= barData.GetLow(getFractal)){
               continue;
            }

            if(isFvg){
               orderBlockTmp[orderBlockCount++] = getFractal;
            }

            tmp[count++] = getFractal;
         }

      }
      
      ArrayResize(result, count);
      for (int i = 0; i < count; i++){
         result[i] = tmp[i];
      }
      
      /*
      for(int i = 0; i<ArraySize(result); i++){
         Print(i," : fractal sweep : ",barData.GetTime(result[i]));
      }
      */

      ArrayResize(orderBlockIndices, orderBlockCount);
      for (int i = 0; i < orderBlockCount; i++){
         orderBlockIndices[i] = orderBlockTmp[i];
      }

      ArrayResize(bearishOrderBlocks, orderBlockCount);
      bearishOBCount = 0;
      for(int i = 0; i < orderBlockCount; i++){
         OrderBlockData ob;
         ob.index      = orderBlockIndices[i];
         ob.high       = barData.GetHigh(orderBlockIndices[i]);
         ob.low        = barData.GetOpen(orderBlockIndices[i]);
         ob.isBullish  = false;
         ob.isActive   = true;
         ob.isMitigated = false;
         bearishOrderBlocks[bearishOBCount++] = ob;
         Print(i," : bearish orderblock : ",barData.GetTime(orderBlockIndices[i]));
      }
         
         
   }
   
   bool identifyFVG(Trend trend, int firstCandleIndex, int secondCandleIndex, int thirdCandleIndex){
      // Validate indices
      if(firstCandleIndex < 0 || secondCandleIndex < 0 || thirdCandleIndex < 0)
         return false;
   
      double firstCandleHigh,firstCandleLow,secondCandleHigh,secondCandleLow,thirdCandleHigh,thirdCandleLow;
      
      firstCandleHigh = barData.GetHigh(firstCandleIndex);
      secondCandleHigh = barData.GetHigh(secondCandleIndex);
      thirdCandleHigh = barData.GetHigh(thirdCandleIndex);
      
      firstCandleLow = barData.GetLow(firstCandleIndex);
      secondCandleLow = barData.GetLow(secondCandleIndex);
      thirdCandleLow = barData.GetLow(thirdCandleIndex);
      
      if(trend == TREND_BULLISH){
         if(secondCandleHigh > firstCandleHigh &&
            secondCandleLow <= firstCandleHigh &&
            secondCandleLow > firstCandleLow &&
            thirdCandleHigh > secondCandleHigh &&
            thirdCandleLow <= secondCandleHigh &&
            thirdCandleLow > secondCandleLow){
            
            // fvg
            return true;   
         }
      }
      else if(trend == TREND_BEARISH){
         if(secondCandleHigh >= firstCandleLow &&
            secondCandleHigh < firstCandleHigh &&
            secondCandleLow < firstCandleLow &&
            thirdCandleHigh >= secondCandleLow &&
            thirdCandleHigh < secondCandleHigh &&
            thirdCandleLow < secondCandleLow){
            // fvg
            return true;
         }
      }
   
      return false;
   }
   
   void filterUnTakenFractal(int &fractals[],int &result[]){
      for(int i = 0; i<ArraySize(fractals); i++){
      
      }
   }
   
   bool checkBullishFractalSweep(int fractalIndex,InducementBand &inducementBand){
      for(int j = fractalIndex-1; j > macdMarketStructure.getPrevMajorLowIndex(); j--){
         if(barData.GetLow(j) < inducementBand.lowerBand){
            // out of candle to process
            // candle are break inducement band
            return false;
         }
         
         if(barData.GetLow(j) >= inducementBand.lowerBand && barData.GetLow(j) <= inducementBand.upperBand){
            // fractal get sweep by wick
            return true;
         }
      }
      
      return false;
   }
   
   bool checkBearishFractalSweep(int fractalIndex,InducementBand &inducementBand){
      for(int j = fractalIndex-1; j > macdMarketStructure.getPrevMajorHighIndex(); j--){
         if(barData.GetHigh(j) > inducementBand.upperBand){
            // out of candle to process
            // candle are break inducement band
            return false;
         }
         
         if(barData.GetHigh(j) >= inducementBand.lowerBand && barData.GetHigh(j) <= inducementBand.upperBand){
            // fractal get sweep by wick
            return true;
         }
      }
      
      return false;
   }
   
   
   
   InducementBand getInducementBand(int inducementIndex){
      double inducementUpperBand,inducementLowerBand;
      if(barData.GetClose(inducementIndex) >= barData.GetOpen(inducementIndex)){
      // inducement bullish candle
         inducementUpperBand = barData.GetOpen(inducementIndex);
         inducementLowerBand = barData.GetLow(inducementIndex);
      }else{
         // inducement bearish candle
         inducementUpperBand = barData.GetHigh(inducementIndex);
         inducementLowerBand = barData.GetOpen(inducementIndex);
      }
      
      InducementBand inducement;
      inducement.upperBand = inducementUpperBand;
      inducement.lowerBand = inducementLowerBand;
      return inducement;
   }
   
   


public:

   void Init(BarData* barDataInstance,MacdMarketStructureClass* macdMarketStructureInstance,FractalClass* fractalInstance,InsideBarClass *insideBarInstance,Fibonacci *fibonacciInstance){
      barData = barDataInstance;
      macdMarketStructure = macdMarketStructureInstance;
      fractal = fractalInstance;
      insideBar = insideBarInstance;
      fibonacci = fibonacciInstance;
      
      isOrderBlockCalculated = false;
      bullishOBCount = 0;
      bearishOBCount = 0;
   }
   
   void update(int Iindex, int totalBars){
      index = Iindex;
      if (index >= totalBars - 1) {
        return;
      }
      
      if(!isOrderBlockCalculated){
         if(macdMarketStructure.isInducementBreak){
            
            calcOrderBlock();
            
         }
      }

      // Invalidate bullish OBs when price breaches the zone
      for(int i = 0; i < bullishOBCount; i++){
         if(!bullishOrderBlocks[i].isActive) continue;
         if(barData.GetLow(index) < bullishOrderBlocks[i].low){
            bullishOrderBlocks[i].isActive = false;
         } else if(barData.GetLow(index) < bullishOrderBlocks[i].high){
            bullishOrderBlocks[i].isMitigated = true;
         }
      }

      // Invalidate bearish OBs when price breaches the zone
      for(int i = 0; i < bearishOBCount; i++){
         if(!bearishOrderBlocks[i].isActive) continue;
         if(barData.GetHigh(index) > bearishOrderBlocks[i].high){
            bearishOrderBlocks[i].isActive = false;
         } else if(barData.GetHigh(index) > bearishOrderBlocks[i].low){
            bearishOrderBlocks[i].isMitigated = true;
         }
      }
      
      if(getMarketBreakAtIndex != macdMarketStructure.marketBreakAtIndex){
            //
            getMarketBreakAtIndex = macdMarketStructure.marketBreakAtIndex;
            isOrderBlockCalculated = false;
            bullishOBCount = 0;
            bearishOBCount = 0;
            
        }
      
      
      
   }

   int getBullishOBCount() { return bullishOBCount; }
   int getBearishOBCount() { return bearishOBCount; }

   OrderBlockData getBullishOB(int i) { return bullishOrderBlocks[i]; }
   OrderBlockData getBearishOB(int i) { return bearishOrderBlocks[i]; }

   bool hasActiveBullishOB() {
      for(int i = 0; i < bullishOBCount; i++)
         if(bullishOrderBlocks[i].isActive) return true;
      return false;
   }

   bool hasActiveBearishOB() {
      for(int i = 0; i < bearishOBCount; i++)
         if(bearishOrderBlocks[i].isActive) return true;
      return false;
   }

}

#endif
