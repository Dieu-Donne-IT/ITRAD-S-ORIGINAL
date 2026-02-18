#ifndef PREMIUMDISCOUNT_MQH
#define PREMIUMDISCOUNT_MQH

#include "BarData.mqh"
#include "MacdMarketStructure.mqh"
#include "Fibonacci.mqh"
#include "Enums.mqh"

class PremiumDiscount {
private:
    BarData* barData;
    MacdMarketStructureClass* macdMarketStructure;
    Fibonacci* fibonacci;
    
    int index;
    double equilibriumPrice;
    double currentPrice;
    PriceZone currentZone;
    Trend cachedTrend;  // Cache trend to avoid redundant calls
    
    void calculateEquilibrium() {
        // Get the 50% Fibonacci level from the array {0.5, 0.618, 0.786, 0.887}
        // Index 0 is defined in Fibonacci.mqh constructor (line 85)
        const int FIBO_50_PERCENT_INDEX = 0;  // Index of 50% level
        
        if (fibonacci.isFiboRetraceCalculated) {
            equilibriumPrice = fibonacci.fiboRetrace.getFiboLevel(FIBO_50_PERCENT_INDEX);
        }
        else {
            equilibriumPrice = 0;
        }
    }
    
    void determineZone() {
        if (equilibriumPrice == 0) {
            currentZone = ZONE_NONE;
            return;
        }
        
        currentPrice = barData.GetClose(index);
        
        // Define tolerance around equilibrium (0.1% = 0.001 multiplier)
        // This accounts for minor price fluctuations and prevents zone flickering
        // Adjust this value for different asset classes or timeframes if needed
        const double EQUILIBRIUM_TOLERANCE_MULTIPLIER = 0.001;
        double tolerance = currentPrice * EQUILIBRIUM_TOLERANCE_MULTIPLIER;
        
        if (MathAbs(currentPrice - equilibriumPrice) <= tolerance) {
            currentZone = ZONE_EQUILIBRIUM;
        }
        else if (currentPrice > equilibriumPrice) {
            currentZone = ZONE_PREMIUM;
        }
        else {
            currentZone = ZONE_DISCOUNT;
        }
    }

public:
    PremiumDiscount() {
        equilibriumPrice = 0;
        currentPrice = 0;
        currentZone = ZONE_NONE;
        cachedTrend = TREND_NONE;
        index = 0;
    }
    
    void Init(BarData* barDataInstance, MacdMarketStructureClass* macdMarketStructureInstance, Fibonacci* fibonacciInstance) {
        barData = barDataInstance;
        macdMarketStructure = macdMarketStructureInstance;
        fibonacci = fibonacciInstance;
    }
    
    void update(int iIndex, int totalBars) {
        if (iIndex >= totalBars - 1) return;
        index = iIndex;
        
        // Cache trend to avoid redundant calls in canBuy() and canSell()
        cachedTrend = macdMarketStructure.getLatestTrend();
        
        calculateEquilibrium();
        determineZone();
    }
    
    // Check if price is in premium zone
    bool isPremium(double price) {
        if (equilibriumPrice == 0) return false;
        return price > equilibriumPrice;
    }
    
    // Check if price is in discount zone
    bool isDiscount(double price) {
        if (equilibriumPrice == 0) return false;
        return price < equilibriumPrice;
    }
    
    // Get equilibrium price (50% level)
    double getEquilibrium() {
        return equilibriumPrice;
    }
    
    // SMV Rule: Buy only in discount during bullish trend
    bool canBuy() {
        return (cachedTrend == TREND_BULLISH && currentZone == ZONE_DISCOUNT);
    }
    
    // SMV Rule: Sell only in premium during bearish trend
    bool canSell() {
        return (cachedTrend == TREND_BEARISH && currentZone == ZONE_PREMIUM);
    }
    
    // Get current price zone
    PriceZone getCurrentZone() {
        return currentZone;
    }
    
    string getCurrentZoneAsString() {
        switch(currentZone) {
            case ZONE_NONE:
                return "None";
            case ZONE_PREMIUM:
                return "Premium";
            case ZONE_DISCOUNT:
                return "Discount";
            case ZONE_EQUILIBRIUM:
                return "Equilibrium";
            default:
                return "Unknown";
        }
    }
};

#endif
