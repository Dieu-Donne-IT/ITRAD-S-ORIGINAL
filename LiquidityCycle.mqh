#ifndef LIQUIDITYCYCLE_MQH
#define LIQUIDITYCYCLE_MQH

#include "BarData.mqh"
#include "MacdMarketStructure.mqh"
#include "Enums.mqh"

class LiquidityCycle {
private:
    BarData* barData;
    MacdMarketStructureClass* macdMarketStructure;
    
    int index;
    Trend cachedTrend;  // Cache trend to avoid redundant calls
    
    // ICRB - Intact Clean Rallye Buyers (for Lows - SSL)
    LiquidityState buyersState;
    int buyersIntactIndex;
    double buyersIntactPrice;
    int buyersCleanIndex;
    double buyersCleanPrice;
    
    // ICRS - Intact Clean Rallye Sellers (for Highs - BSL)
    LiquidityState sellersState;
    int sellersIntactIndex;
    double sellersIntactPrice;
    int sellersCleanIndex;
    double sellersCleanPrice;
    
    // Check if price has swept a level (wick break then return)
    bool checkSweepAbove(double targetPrice) {
        if (index < 1) return false;
        double currentHigh = barData.GetHigh(index);
        double currentClose = barData.GetClose(index);
        double currentOpen = barData.GetOpen(index);
        
        // Check if wick broke above target but body closed below
        if (currentHigh > targetPrice) {
            double bodyTop = MathMax(currentOpen, currentClose);
            if (bodyTop < targetPrice) {
                return true;
            }
        }
        return false;
    }
    
    bool checkSweepBelow(double targetPrice) {
        if (index < 1) return false;
        double currentLow = barData.GetLow(index);
        double currentClose = barData.GetClose(index);
        double currentOpen = barData.GetOpen(index);
        
        // Check if wick broke below target but body closed above
        if (currentLow < targetPrice) {
            double bodyBottom = MathMin(currentOpen, currentClose);
            if (bodyBottom > targetPrice) {
                return true;
            }
        }
        return false;
    }
    
    // Update ICRS (Sellers - Highs)
    // Tracks BSL (Buy Side Liquidity) - relevant during BULLISH trends
    void updateSellersState() {
        if (isBullishTrend()) {
            int prevHighIndex = macdMarketStructure.getPrevMajorHighIndex();
            double prevHighPrice = macdMarketStructure.getPrevMajorHighPrice();
            
            if (prevHighIndex != -1 && prevHighPrice > 0) {
                // Check state transitions
                if (sellersState == LIQ_NONE || sellersState == LIQ_RALLYE) {
                    // New intact level detected
                    if (sellersIntactIndex != prevHighIndex) {
                        sellersState = LIQ_INTACT;
                        sellersIntactIndex = prevHighIndex;
                        sellersIntactPrice = prevHighPrice;
                        sellersCleanIndex = -1;
                        sellersCleanPrice = 0;
                    }
                }
                else if (sellersState == LIQ_INTACT) {
                    // Check for sweep (clean)
                    if (checkSweepAbove(sellersIntactPrice)) {
                        sellersState = LIQ_CLEAN;
                        sellersCleanIndex = index;
                        sellersCleanPrice = sellersIntactPrice;
                    }
                }
                else if (sellersState == LIQ_CLEAN) {
                    // Check for rallye confirmation (BOS after clean)
                    MarketStructureType msType = macdMarketStructure.latestMarketStructure;
                    if (msType == MS_BULLISH_BOS && macdMarketStructure.marketBreakAtIndex > sellersCleanIndex) {
                        sellersState = LIQ_RALLYE;
                    }
                }
            }
        }
    }
    
    // Update ICRB (Buyers - Lows)
    // Tracks SSL (Sell Side Liquidity) - relevant during BEARISH trends
    void updateBuyersState() {
        if (!isBullishTrend()) {
            int prevLowIndex = macdMarketStructure.getPrevMajorLowIndex();
            double prevLowPrice = macdMarketStructure.getPrevMajorLowPrice();
            
            if (prevLowIndex != -1 && prevLowPrice > 0) {
                // Check state transitions
                if (buyersState == LIQ_NONE || buyersState == LIQ_RALLYE) {
                    // New intact level detected
                    if (buyersIntactIndex != prevLowIndex) {
                        buyersState = LIQ_INTACT;
                        buyersIntactIndex = prevLowIndex;
                        buyersIntactPrice = prevLowPrice;
                        buyersCleanIndex = -1;
                        buyersCleanPrice = 0;
                    }
                }
                else if (buyersState == LIQ_INTACT) {
                    // Check for sweep (clean)
                    if (checkSweepBelow(buyersIntactPrice)) {
                        buyersState = LIQ_CLEAN;
                        buyersCleanIndex = index;
                        buyersCleanPrice = buyersIntactPrice;
                    }
                }
                else if (buyersState == LIQ_CLEAN) {
                    // Check for rallye confirmation (BOS after clean)
                    MarketStructureType msType = macdMarketStructure.latestMarketStructure;
                    if (msType == MS_BEARISH_BOS && macdMarketStructure.marketBreakAtIndex > buyersCleanIndex) {
                        buyersState = LIQ_RALLYE;
                    }
                }
            }
        }
    }
    
    // Helper method to check current trend (uses cached value)
    bool isBullishTrend() {
        return cachedTrend == TREND_BULLISH;
    }

public:
    LiquidityCycle() {
        buyersState = LIQ_NONE;
        sellersState = LIQ_NONE;
        buyersIntactIndex = -1;
        buyersIntactPrice = 0;
        buyersCleanIndex = -1;
        buyersCleanPrice = 0;
        sellersIntactIndex = -1;
        sellersIntactPrice = 0;
        sellersCleanIndex = -1;
        sellersCleanPrice = 0;
        cachedTrend = TREND_NONE;
        index = 0;
    }
    
    void Init(BarData* barDataInstance, MacdMarketStructureClass* macdMarketStructureInstance) {
        barData = barDataInstance;
        macdMarketStructure = macdMarketStructureInstance;
    }
    
    void update(int iIndex, int totalBars) {
        if (iIndex >= totalBars - 1) return;
        index = iIndex;
        
        // Cache trend to avoid redundant calls
        cachedTrend = macdMarketStructure.getLatestTrend();
        
        updateSellersState();
        updateBuyersState();
    }
    
    // Public getters
    LiquidityState getBuyersState() {
        return buyersState;
    }
    
    LiquidityState getSellersState() {
        return sellersState;
    }
    
    string getBuyersStateAsString() {
        switch(buyersState) {
            case LIQ_NONE:
                return "None";
            case LIQ_INTACT:
                return "Intact";
            case LIQ_CLEAN:
                return "Clean";
            case LIQ_RALLYE:
                return "Rallye";
            default:
                return "Unknown";
        }
    }
    
    string getSellersStateAsString() {
        switch(sellersState) {
            case LIQ_NONE:
                return "None";
            case LIQ_INTACT:
                return "Intact";
            case LIQ_CLEAN:
                return "Clean";
            case LIQ_RALLYE:
                return "Rallye";
            default:
                return "Unknown";
        }
    }
    
    // Check if sweep has completed (same as canRallyeStart per SMV Rule #5)
    bool isSweepComplete() {
        return canRallyeStart();
    }
    
    // SMV Rule #5: "Without any liquidity taken, no rally can be launched"
    bool canRallyeStart() {
        if (isBullishTrend()) {
            return (sellersState == LIQ_CLEAN || sellersState == LIQ_RALLYE);
        }
        else {
            return (buyersState == LIQ_CLEAN || buyersState == LIQ_RALLYE);
        }
    }
    
    int getSweepIndex() {
        return isBullishTrend() ? sellersCleanIndex : buyersCleanIndex;
    }
    
    double getSweepPrice() {
        return isBullishTrend() ? sellersCleanPrice : buyersCleanPrice;
    }
};

#endif
