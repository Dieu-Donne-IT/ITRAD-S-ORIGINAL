#ifndef ORDERBLOCK_MQH
#define ORDERBLOCK_MQH

#include "Enums.mqh";
#include "BarData.mqh";
#include "MacdMarketStructure.mqh";
#include "Fractal.mqh";
#include "CandleBreakAnalyzerStatic.mqh";
#include "InsideBarClass.mqh";
#include "Fibonacci.mqh";

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
   
   string bullishOBNames[];
   string bearishOBNames[];
   
   struct InducementBand{
      double upperBand;
      double lowerBand;
   };
   
   void clearOrderBlockObjects(){
      for(int i = 0; i < ArraySize(bullishOBNames); i++){
         ObjectDelete(0, bullishOBNames[i]);
      }
      ArrayResize(bullishOBNames, 0);
      
      for(int i = 0; i < ArraySize(bearishOBNames); i++){
         ObjectDelete(0, bearishOBNames[i]);
      }
      ArrayResize(bearishOBNames, 0);
   }
   
   void drawBullishOB(int fractalIndex, int inducementIdx){
      string objName = "SMC_BullOB_" + IntegerToString(fractalIndex);
      ObjectDelete(0, objName);
      datetime t1 = barData.GetTime(fractalIndex);
      datetime t2 = barData.GetTime(inducementIdx);
      double price1 = barData.GetHigh(fractalIndex);
      double price2 = barData.GetLow(fractalIndex);
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, t1, price1, t2, price2);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, objName, OBJPROP_FILL, false);
      ObjectSetInteger(0, objName, OBJPROP_BACK, true);
      int sz = ArraySize(bullishOBNames);
      ArrayResize(bullishOBNames, sz + 1);
      bullishOBNames[sz] = objName;
   }
   
   void drawBearishOB(int fractalIndex, int inducementIdx){
      string objName = "SMC_BearOB_" + IntegerToString(fractalIndex);
      ObjectDelete(0, objName);
      datetime t1 = barData.GetTime(fractalIndex);
      datetime t2 = barData.GetTime(inducementIdx);
      double price1 = barData.GetHigh(fractalIndex);
      double price2 = barData.GetLow(fractalIndex);
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, t1, price1, t2, price2);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, objName, OBJPROP_FILL, false);
      ObjectSetInteger(0, objName, OBJPROP_BACK, true);
      int sz = ArraySize(bearishOBNames);
      ArrayResize(bearishOBNames, sz + 1);
      bearishOBNames[sz] = objName;
   }
   
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
      
      int inducementIndex = macdMarketStructure.getInducementIndex();
      
      for(int i = 0; i<ArraySize(fractalFromRange); i++){
      
         int getFractal = fractalFromRange[i];
         
         InducementBand inducementBand = getInducementBand(getFractal);
         
         bool isFractalSweep = checkBullishFractalSweep(getFractal,inducementBand);
         
         if(isFractalSweep){
         
            bool isFvg = false;
            
            isFvg = identifyFVG(TREND_BULLISH,getFractal,getFractal+1,getFractal+2);
            
            // check is orderblock are taked
            int scanStart = getFractal + 3;
            int scanCount = inducementIndex - scanStart;
            if(scanCount <= 0) continue;
            
            int lowestLowIndex = barData.getLowestLowValueByRange(scanStart, scanCount);
            double lowestLowPrice = barData.GetLow(lowestLowIndex);
            
            if(lowestLowPrice<=barData.GetHigh(getFractal)){
               continue;
            }
            
            if(isFvg){
               orderBlockTmp[orderBlockCount++] = getFractal;
               drawBullishOB(getFractal, inducementIndex);
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
      int count = 0,orderBlockCount = 0;
      
      int inducementIndex = macdMarketStructure.getInducementIndex();
      
      for(int i = 0; i<ArraySize(fractalFromRange); i++){
         
         int getFractal = fractalFromRange[i];
         
         InducementBand inducementBand = getInducementBand(getFractal);
         
         bool isFractalSweep = checkBearishFractalSweep(getFractal,inducementBand);
         
         if(isFractalSweep){
         
            bool isFvg = false;
            
            isFvg = identifyFVG(TREND_BEARISH,getFractal,getFractal+1,getFractal+2);
            
            // check is orderblock are taked
            int scanStart = getFractal + 3;
            int scanCount = inducementIndex - scanStart;
            if(scanCount <= 0) continue;
            
            int highestHighIndex = barData.getHighestHighValueByRange(scanStart, scanCount);
            double highestHighPrice = barData.GetHigh(highestHighIndex);
            
            if(highestHighPrice >= barData.GetLow(getFractal)){
               continue;
            }
            
            if(isFvg){
               orderBlockTmp[orderBlockCount++] = getFractal;
               drawBearishOB(getFractal, inducementIndex);
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
      
      if(getMarketBreakAtIndex != macdMarketStructure.marketBreakAtIndex){
            getMarketBreakAtIndex = macdMarketStructure.marketBreakAtIndex;
            clearOrderBlockObjects();
            isOrderBlockCalculated = false;
        }
      
      
      
   }

}

#endif
