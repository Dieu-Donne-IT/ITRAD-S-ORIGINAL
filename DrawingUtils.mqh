#ifndef DRAWINGUTILS_MQH
#define DRAWINGUTILS_MQH

class DrawingUtils {
public:
   static bool DrawRectangle(
      string   name,
      datetime timeStart,
      double   priceHigh,
      datetime timeEnd,
      double   priceLow,
      color    clr,
      int      alpha = 80,
      bool     fill  = true
   ) {
      ObjectDelete(0, name);

      if(!ObjectCreate(0, name, OBJ_RECTANGLE, 0, timeStart, priceHigh, timeEnd, priceLow))
         return false;

      ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
      ObjectSetInteger(0, name, OBJPROP_FILL,      fill);
      ObjectSetInteger(0, name, OBJPROP_BACK,      true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN,    true);

      return true;
   }

   static void DeleteObjectsByPrefix(string prefix) {
      int total = ObjectsTotal(0, -1, -1);
      for(int i = total - 1; i >= 0; i--) {
         string objName = ObjectName(0, i, -1, -1);
         if(StringFind(objName, prefix) == 0)
            ObjectDelete(0, objName);
      }
   }
};

#endif
