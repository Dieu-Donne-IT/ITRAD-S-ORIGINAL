#ifndef PREMIUMDISCOUNT_MQH
#define PREMIUMDISCOUNT_MQH

class PremiumDiscount {

public:
   PremiumDiscount() {}

   void Init() {}

   void update(int index, int totalBars) {}

   // Stub implementations — full Premium/Discount logic will be added in a future PR
   bool canBuy()  { return true; }
   bool canSell() { return true; }

   string getZoneAsString() { return "Neutral"; }

}

#endif
