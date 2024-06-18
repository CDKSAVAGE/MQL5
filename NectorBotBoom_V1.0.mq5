//+------------------------------------------------------------------+
//|                                                NectorBot1000.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property indicator_chart_window
#property link      "cdksavage@gmail.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>

input group "Account Protection"
input double StopLoSS =8000;
input double TakeProfit = 5000;
input double lotage = 0.20;
input double dailytp =4;
input int magicnumber = 23456799;
input int how_many_positions=1;
input group "BreakEven And Trailing StopLoss"




input group "First Moving Average(fastMA)"
input int period= 9;
input int shift= 0;
input ENUM_MA_METHOD firstMAMethod=MODE_EMA;

input group "Second Moving Average(SecondMA)"
input int s_period= 21;
//input int shift=0;
input ENUM_MA_METHOD SecondMAMethod=MODE_EMA;


input group "Thrid Moving Average(DailyMA)"
input int t_period=55;
//input int shift=0;
input ENUM_MA_METHOD ThirdMAMethod=MODE_EMA;

int MACD_h;

/* Arrays where the indicator data is stored */
double MACD[];
double SIGNAL[];
int firstMA,SecondMA,ThirdMA;
double   RSIOnMABuffer[];
double fma[],sma[],tma[];

int totalBars =0;


ulong posTicket(uint index){return PositionGetTicket(index);}
string posSymbol(){return PositionGetString(POSITION_SYMBOL);}
int posType(){return (int) PositionGetInteger(POSITION_TYPE);}

double Ask(){return NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);}
double Bid(){return NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);}
double posOpen_Prc(){return PositionGetDouble(POSITION_PRICE_OPEN);}
double posSL(){return PositionGetDouble(POSITION_SL);}
double posTP(){return PositionGetDouble(POSITION_TP);}

input group "BreakEven And Trailing StopLoss"
input double 
      breakEven_After_Pts=150,
      breakEven_At_Pts=1000;
      
input int 
         Trail_Stop = 3000,
         Trail_Step =50,
         Trail_Gap  =50;
         

int indicator;
int indicator2;
int harmonic_pattern;

 color clr;
CTrade trade;
CSymbolInfo    m_symbol; 

int OnInit()
  { 
    Email();
    firstMA=iMA(_Symbol,PERIOD_CURRENT,period,shift,firstMAMethod,PRICE_CLOSE);
    if(firstMA==INVALID_HANDLE){
    return(INIT_FAILED);
   }
    SecondMA = iMA(_Symbol,PERIOD_CURRENT,s_period,shift,SecondMAMethod,PRICE_CLOSE);
    if(SecondMA==INVALID_HANDLE){
    return(INIT_FAILED);
    }
    ThirdMA = iMA(_Symbol,PERIOD_CURRENT,t_period,shift,ThirdMAMethod,PRICE_CLOSE);
    if(ThirdMA == INVALID_HANDLE){
    return(INIT_FAILED);
    }
    MACD_h = iMACD(_Symbol,PERIOD_CURRENT,12,26,9,PRICE_CLOSE);
    ArraySetAsSeries(fma,true);
    ArraySetAsSeries(sma,true);
    ArraySetAsSeries(tma,true);
    
    indicator=iCustom(_Symbol,PERIOD_CURRENT,"Z3MA");
    indicator2=iCustom(_Symbol,PERIOD_CURRENT,"myIndicator");
   harmonic_pattern = iCustom(_Symbol,PERIOD_CURRENT,"HarmonicPatternFinderV3");
    
   return(INIT_SUCCEEDED);
  }
  

  
void OnDeinit(const int reason)
  {
   Print(GetLastError());
   
  }







void OnTick()
{
    if (checkDailyTarget(dailytp))
    {
        // Check if the total number of open positions exceeds the maximum allowed
        if (PositionsTotal() >= how_many_positions)
        {
            Print("Positions limit reached");
            return; // Exit the function without opening new positions
        }

        // Your existing trading logic goes here
        
        // Example of your existing trading logic:
        breakEven();
        TrailingStop();
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
         CopyBuffer(MACD_h, 0, 1, 4, MACD);
         CopyBuffer(MACD_h, 1, 1, 4, SIGNAL);

        int bars = iBars(_Symbol, PERIOD_CURRENT);
        CopyBuffer(indicator,2,0,3,RSIOnMABuffer);
        if (totalBars == bars)
            return;
        totalBars = bars;

        if (!CopyBuffer(firstMA, 0, 0, 3, fma))
            return;
        if (CopyBuffer(SecondMA, MAIN_LINE, 0, 3, sma) < 3)
            return;
        if (CopyBuffer(ThirdMA, 0, 0, 3, tma) < 3)
            return;

        double fma1 = fma[1];
        double fma2 = fma[2];

        double sma1 = sma[1];
        double sma2 = sma[2];

        double tma1 = tma[1];
        double tma2 = tma[2];

        if (fma1 < sma1 && !(fma2 < sma2) && sma1 < tma1)
        {
            clr = clrBlack;
            ChartSetInteger(0, CHART_COLOR_BACKGROUND, clr);

            Comment("SELLING NOW");
            double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
            double sl = NormalizeDouble(StopLoSS * _Point, _Digits);
            double tp = NormalizeDouble(TakeProfit * _Point, _Digits);
            trade.Sell(lotage, _Symbol, Bid, Bid + sl, Bid - tp);
        }
        if (fma1 > sma1 && !(fma2 > sma2) && sma1 > tma1)
        {
            clr = clrBrown;
            ChartSetInteger(0, CHART_COLOR_BACKGROUND, clr);
            Comment("BUYING NOW...LETS CATCH SOME SPIKES");
        }
    }
}

void Email(){
     string emailHeader_subject="EXPERT INITIALIZATION";
     string msg="EA INITIALIZED ON THE CHART"+_Symbol;
     bool isSendMail=SendMail(emailHeader_subject,msg);
     if(isSendMail == true){
       Print("EMAIL HAS BEEN SENT SUCCESSFULLY");
     }
     else if(!isSendMail){
       Print("UNABLE TO SEND THE EMAIL: ERROR CODE = ",GetLastError());
     }
}

void Email_Telegram_Notification(){
  string email_subject_header = " NECTORBOT CHAT UPDATE";
  string my_message = ("CONGRATULATIONS, THE TARGET PROFIT  HAS BEEN ARCHIVED....REMEMBER TO REINITIALIZE THE BOT...SINCE EXPERT REMOVE FUNCTION WAS CALLED");
  bool mail_it = SendMail(email_subject_header,my_message);
  if(mail_it == true){
   Print("EMAIL SENT SUCCESSFULLY");
  
  }
  else if(!mail_it){
     Print("UNABLE TO SEND THE EMAIL : ERROR CODE = ", GetLastError());
  }

}



/// Fucntion ya BreakEven

void breakEven(){
  for(int i=PositionsTotal()-1;i>=0;i--){
  ulong tkt=posTicket(i);
  if(tkt>0){
    if(posSymbol()==_Symbol){
      if(breakEven_After_Pts > 0 ) {
        if (posType()==POSITION_TYPE_BUY) {
           if(Bid() >= posOpen_Prc()+breakEven_After_Pts*_Point
             +breakEven_At_Pts*_Point ){
             if (posOpen_Prc()+breakEven_At_Pts*_Point > posSL()) {
               trade.PositionModify(tkt,posOpen_Prc()
                 +breakEven_At_Pts*_Point,posTP());
               Print("=====BREAKEVEN(BUY) Applied @ price",
                 NormalizeDouble( posOpen_Prc()+breakEven_At_Pts*_Point,_Digits), "====="
                );
             }
           }
         }
         else if (posType()==POSITION_TYPE_SELL) {
           if(Ask() <= posOpen_Prc()-breakEven_After_Pts*_Point
             -breakEven_At_Pts*_Point ){
             if (posOpen_Prc()-breakEven_At_Pts*_Point < posSL()
                || posSL() == 0) {
               trade.PositionModify(tkt,posOpen_Prc()
                 -breakEven_At_Pts*_Point,posTP());
               Print("=====BREAKEVEN(SELL) Applied @ price",
                 NormalizeDouble( posOpen_Prc()+breakEven_At_Pts*_Point,_Digits), "====="
                );
             }
           }
         }
        }
      }
    }
   }
}



// Function ya Trailing stopLoss
void TrailingStop(){
  double
       busl = Bid()-Trail_Stop*_Point,
       sellsl= Ask()+Trail_Stop*_Point;
  for(int i=PositionsTotal()-1;i>=0;i--){
  ulong tkt=posTicket(i);
  if(tkt>0){
    if(posSymbol()==_Symbol){
      if(breakEven_After_Pts > 0 ) {
        if (posType()==POSITION_TYPE_BUY) {
           if(busl-Trail_Gap*_Point > posOpen_Prc() && (posSL()==0 ||(busl > posSL()
               &&busl > posSL()+Trail_Step*_Point))){
             
               trade.PositionModify(tkt,busl,posTP());
               Print("+++++TRAILSTOP(BUY) Applied @ price",sellsl,"+++++");
             
           }
         }
  else if (posType()==POSITION_TYPE_SELL) {
           if(sellsl+ Trail_Gap*_Point < posOpen_Prc() && (posSL()==0 ||sellsl < posSL())
               &&(sellsl < posSL()-Trail_Step*_Point || posSL()==0)){
             
               trade.PositionModify(tkt,sellsl,posTP());
               Print("+++++TRAILSTOP(SELL) Applied @ price",busl,"+++++");
             
           }
         }        }
      }
    }
   }
}









// Function ya kuangalia dailyProfit target.........Nimetoa Expert Remove function so ina G restart enyewe midnight.
bool checkDailyTarget(double dailyTarget) {
    static bool dailyTargetReached = false;
    static datetime lastCheckedTime = 0;
    
    datetime now = TimeCurrent();
    datetime D1_0 = iTime(_Symbol, PERIOD_D1, 0);
    string currentDate = TimeToString(D1_0, TIME_DATE);
    
    // Check if it's a new day and reset the dailyTargetReached flag
    if (D1_0>lastCheckedTime) {
        dailyTargetReached = false;
        Print("It's a new day!");
        lastCheckedTime = now;
    }
    
    double totalProfit = 0;
    
    // Select historical deals within the current day
    if (HistorySelect(D1_0, now)) {
        int totalDeals = HistoryDealsTotal();
        
        for (int i = 0; i < totalDeals; i++) {
            ulong ticket = HistoryDealGetTicket(i);
            
            if (HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
                double latestProfit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                totalProfit += latestProfit;
            }
        }
    }
    
    // Check if daily target has been reached
    if (!dailyTargetReached && totalProfit >= dailyTarget) {
        Print("Daily target has been reached at ", TimeToString(now));
        dailyTargetReached = true;
    }

    return !dailyTargetReached; // Return false if daily target reached to stop opening positions
}
