#ifndef FAIRVALUEGAP_MQH
#define FAIRVALUEGAP_MQH

struct FVGZone {
   double upper;
   double lower;
};

class FairValueGap{

private:
   FVGZone bullishFVGs[];
   FVGZone bearishFVGs[];

public:

   void calculate(){
   
   }

   bool getLatestBullishFVG(FVGZone &zone){
      int count = ArraySize(bullishFVGs);
      if(count == 0) return false;
      zone = bullishFVGs[count - 1];
      return true;
   }

   bool getLatestBearishFVG(FVGZone &zone){
      int count = ArraySize(bearishFVGs);
      if(count == 0) return false;
      zone = bearishFVGs[count - 1];
      return true;
   }

   int getFVGCount(){
      return ArraySize(bullishFVGs) + ArraySize(bearishFVGs);
   }

}

#endif