//+------------------------------------------------------------------+
//|                                                        RSIMA.mq5 |
//|                                            Copyright 2020, ernst |
//|                             https://www.mql5.com/en/users/pippod |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, ernst"
#property link      "https://www.mql5.com/en/users/pippod"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot RSI
#property indicator_label1  "RSI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrNONE
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot MA
#property indicator_label2  "MA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGreen
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//---
#property indicator_maximum 80
#property indicator_level2  70
#property indicator_level1  20
#property indicator_minimum 10
//--- input parameters
input int      RSIPeriod=12;
input ENUM_APPLIED_PRICE RSIPrice=PRICE_CLOSE;
input int      MAPeriod=9;
input ENUM_MA_METHOD MAMethod=MODE_EMA;
input int      MAShift=0;
//--- indicator buffers
double         RSIBuffer[];
double         MABuffer[];
//---
int handleRSI=INVALID_HANDLE,handleMA=INVALID_HANDLE;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if((handleRSI=iRSI(_Symbol,_Period,RSIPeriod,RSIPrice))==INVALID_HANDLE ||
      (handleMA=iMA(_Symbol,_Period,MAPeriod,MAShift,MAMethod,handleRSI))==INVALID_HANDLE)
     return(INIT_FAILED);
//---
   IndicatorSetString(INDICATOR_SHORTNAME,StringFormat("RSI(%d) %s(%d)",RSIPeriod,StringSubstr(EnumToString(MAMethod),5),MAPeriod));
   IndicatorSetInteger(INDICATOR_DIGITS,1);
//--- indicator buffers mapping
   SetIndexBuffer(0,RSIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,MABuffer,INDICATOR_DATA);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---
   int toCopy=(rates_total!=prev_calculated)?rates_total-prev_calculated:1;
//---
   if(CopyBuffer(handleRSI,0,0,toCopy,RSIBuffer)!=toCopy ||
      CopyBuffer(handleMA ,0,0,toCopy,MABuffer )!=toCopy)
      return(0);
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
