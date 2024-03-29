#include<Trade/Trade.mqh>

input group "If BUY "
input int takeprofit=1000;
input int stoploss=1000;
input double lot=0.20;
input int magicnumber=123456;


input group " if SELL "
input int TakeProfit=2500;
input int StopLoss=7000;
input double Lot=0.20;

input group"Account Protection"
input double daiyTp=2;
input bool USE_BE=false;


input group" messages and notification"
input string email="user@gmail.com";

input group "fastMA"
input int period=14;
input int shift=0;
input ENUM_MA_METHOD fastMAMethod=MODE_EMA;

input group "slowMA"
input int perioD=50;
input int Shift=0;
input ENUM_MA_METHOD slowMAMethod=MODE_EMA;

enum BE_variations{
static_BE,
Dynamic_BE
};


input BE_variations BE_variation=static_BE;



int FastMA_handle;
int SlowMA_handle;
int indicator;

double ma14[];
double ma50[];
double   RSIOnMABuffer[];

bool time_flag;
ulong trade_ticket;

static bool Buy_Once=false,Sell_Once=false;
CTrade trade;
int OnInit()
  {
   
   
   FastMA_handle=iMA(_Symbol,PERIOD_CURRENT,period,shift,slowMAMethod,PRICE_CLOSE);
   if(FastMA_handle==INVALID_HANDLE){
   Print("failed to create handle for ",FastMA_handle);
   return(INIT_FAILED);
   }
   
   SlowMA_handle=iMA(_Symbol,PERIOD_CURRENT,perioD,Shift,fastMAMethod,PRICE_CLOSE);
   if(SlowMA_handle==INVALID_HANDLE){
   Print("failed to create an indicator handle for",SlowMA_handle);
   return(INIT_FAILED);
   }
   
   indicator=iCustom(_Symbol,PERIOD_CURRENT,"myRSIMA");
   if(indicator==INVALID_HANDLE){
   Print("failed to create the indicator handle for",indicator);
   }
   return(INIT_SUCCEEDED);
  }


void OnDeinit(const int reason)
  {

  }

void OnTick()
  {
  
   dailyTarget();
    if(BE_variation==static_BE){
   simple_BE_func();
   }
   else if(BE_variation==Dynamic_BE){
   
   Dynamic_BE_func();
   }
   datetime CurrentTimeBar0=iTime(_Symbol,_Period,0);
   static datetime SignalTime=CurrentTimeBar0;
   
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
  ArraySetAsSeries(ma14,true);
  ArraySetAsSeries(ma50,true);
  ArraySetAsSeries(RSIOnMABuffer,true);
  CopyBuffer(SlowMA_handle,0,0,3,ma14);
  CopyBuffer(FastMA_handle,0,0,3,ma50);
  CopyBuffer(indicator,2,0,3,RSIOnMABuffer);
   
   
   
   
  
  
  if(ma50[1]>ma14[1]&&ma14[0]<ma50[0]&&RSIOnMABuffer[0]>=20&&SignalTime!=CurrentTimeBar0){
  SignalTime=CurrentTimeBar0;
  Comment("<<TIME TO BUY>>LETS HUNT SPIKES");
  
  if(PositionsTotal()==0&&!Buy_Once){
  Buy_Once=true;Sell_Once=false;
  double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
  
//trade.Sell(0.2,_Symbol,Bid,Bid+4000*_Point,Bid-5000*_Point,"SELL");

//trade_ticket=trade.ResultOrder();

time_flag=false;
EventSetTimer(PeriodSeconds(PERIOD_CURRENT)*45);
request.action=TRADE_ACTION_DEAL;
request.type=ORDER_TYPE_BUY;
//openTimeSell=iTime(_Symbol,_Period,0);
request.symbol=_Symbol;
request.volume=lot;
request.type_filling=ORDER_FILLING_FOK;
request.price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);

request.tp=Ask+(takeprofit*_Point);
request.sl=Ask-(stoploss*_Point);
request.deviation=5;
request.magic=magicnumber;


if(!OrderSend(request,result)){
Print("no");
}else{


PrintFormat("retcode=%u deal=%I64u order=I64u",result.retcode,result.deal,result.order);
trade.PositionClose(trade_ticket);

 }
  }
  
  
   
  }
   else if(ma50[1]<ma14[1]&&ma14[0]>ma50[0]&&RSIOnMABuffer[0]<=80&&SignalTime!=CurrentTimeBar0){
   
  
  Print("trueificd");
  Comment("<<TIME TO SELL>>LETS GO SCALPING");
  double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
  if(PositionsTotal()==0&&!Sell_Once){
   Buy_Once=false;Sell_Once=true;
 
//trade.Sell(0.2,_Symbol,Bid,Bid+1000*_Point,Bid-5000*_Point,"SELL");

//trade_ticket=trade.ResultOrder();

time_flag=false;
EventSetTimer(PeriodSeconds(PERIOD_CURRENT)*45);
request.action=TRADE_ACTION_DEAL;
request.type=ORDER_TYPE_SELL;
//openTimeSell=iTime(_Symbol,_Period,0);
request.symbol=_Symbol;
request.volume=Lot;
request.type_filling=ORDER_FILLING_FOK;
request.price=SymbolInfoDouble(_Symbol,SYMBOL_BID);

request.tp=Bid-(TakeProfit*_Point);
request.sl=Bid+(StopLoss*_Point);
request.deviation=5;
request.magic=magicnumber;
if(!OrderSend(request,result)){
Print("no");
}else{


PrintFormat("retcode=%u deal=%I64u order=I64u",result.retcode,result.deal,result.order);
trade.PositionClose(trade_ticket);
 }
  }
}

}
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {

   
  }

void OnTimer()
  {
//---
time_flag=true;
EventKillTimer();
   
  }
  
  
  void dailyTarget(){
  
  double dayprof=0.0;
  dayprof=0.0;
trade.SetExpertMagicNumber(magicnumber);
datetime end=TimeCurrent();
string sdate=TimeToString(TimeCurrent(),TIME_DATE);
datetime start=StringToTime(sdate);
HistorySelect(start,end);
int TotalDeals=HistoryDealsTotal();
for(int i=0;i<TotalDeals;i++){
ulong Ticket=HistoryDealGetTicket(i);
if(HistoryDealGetInteger(Ticket,DEAL_ENTRY)==DEAL_ENTRY_OUT){
if(HistoryDealGetInteger(Ticket,DEAL_TIME)<sdate){

double latestprof=HistoryDealGetDouble(Ticket,DEAL_PROFIT);
dayprof+=latestprof;

}
if(dayprof>=daiyTp){

ExpertRemove();
SendMail("Expert has been stopped remember to restart tomorrow",email);
SendNotification("PROFIT REACHED,EXPERT HAS STOPED TRADING TODAY, MAKE SURE TO RESTART TOMORROW");
Print("profit reached");
}

}





}
  
  }
  
  
  
   input double BE_trigger_points=100;
  input double BE_Move_points=50;
  
  
  void simple_BE_func(){
  if(!USE_BE)return;
  for(int x=0;x<PositionsTotal();x++){
    uint ticket=PositionGetTicket(x);
    double open_price=PositionGetDouble(POSITION_PRICE_OPEN),current_price=PositionGetDouble(POSITION_PRICE_CURRENT);
    double pos_tp=PositionGetDouble(POSITION_TP),pos_sl=PositionGetDouble(POSITION_SL);
    int pos_type=PositionGetInteger(POSITION_TYPE);
    double distance=0;
    if(pos_type==POSITION_TYPE_BUY){
     distance=(current_price-open_price)/Point();
     if(distance>=BE_trigger_points&&pos_sl<open_price){
      trade.PositionModify(ticket,open_price+BE_Move_points*Point(),pos_tp);
      }
     }
   
   else{
     distance=(open_price-current_price)/Point();
     if(distance>=BE_trigger_points&&pos_sl>open_price){
      trade.PositionModify(ticket,open_price-BE_Move_points*Point(),pos_tp);
    }
  }
   }
   }
   
   
   
   input double BE_trigger_pct=10;
  input double BE_Move_pct=5;
     void Dynamic_BE_func(){
     if(!USE_BE)return;
     double trigger_points=0, move_points=0;
  for(int x=0;x<PositionsTotal();x++){
    uint ticket=PositionGetTicket(x);
    double open_price=PositionGetDouble(POSITION_PRICE_OPEN),current_price=PositionGetDouble(POSITION_PRICE_CURRENT);
    double pos_tp=PositionGetDouble(POSITION_TP),pos_sl=PositionGetDouble(POSITION_SL);
    int pos_type=PositionGetInteger(POSITION_TYPE);
    double distance=0;
    double distance_2=0;
    if(pos_type==POSITION_TYPE_BUY){
     distance=(pos_tp-open_price)/Point();
     trigger_points=(distance)/100*BE_trigger_points;
     move_points=(distance)/100*BE_Move_pct;
     distance_2=(current_price-open_price);
     trigger_points*=Point();move_points*=Point();
     if(trigger_points>=distance_2&&pos_sl<open_price){
      trade.PositionModify(ticket,open_price+move_points,pos_tp);
      
      }
    
      
     }
   
   else{
     distance=(open_price-pos_tp)/Point();
     trigger_points=(distance)/100*BE_trigger_points;
     move_points=(distance)/100*BE_Move_pct;
     distance_2=(open_price-current_price);
     trigger_points*=Point();move_points*=Point();
      if(trigger_points>=distance_2&&pos_sl>open_price){
      trade.PositionModify(ticket,open_price-move_points,pos_tp);
     
    }
  }
   }
   }
   
   
 
  