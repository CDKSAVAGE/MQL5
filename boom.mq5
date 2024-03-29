
#include<Trade\Trade.mqh>
#include<Trade\PositionInfo.mqh>
#include<Trade\OrderInfo.mqh>

#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.cdkfx.com"
#property version   "1.00"


input int magicnumber=1234;
double THRESHOLD=10;// i wanted to use this as daily tp but it didn't work so i had to use a dailytp
input double dailytp=1.0;
input string email="cdksavage7@gmail.com";
input double takeprofit=5000;
input double stoploss=8000;
int day=0;
int MACD_HNDLE;
double MACD;
double SIGNL;
double MACD_ARRAY[];
double MACD_SIGNL[];
/*MOVING AVERAGE HANDLE*/
int IMA_HANDLE;
int IMA_HANDLE2;
double IMA_HANDLE_ARRAY[];
double IMA_HANDLE2_ARRAY[];

int heiken_Ashi;
bool dayprof;
static datetime recomence_trading=0;
datetime openTimeSell=0;

int currentBarTime;

MqlRates priceinformation[];
CTrade trade;
ulong trade_ticket=0;
bool time_flag=true;

double total_Profit(){
double profit=0;
for(int i=0;i<PositionsTotal();i++){
ulong ticket=PositionGetTicket(i);
PositionSelectByTicket(ticket);

profit+=PositionGetDouble(POSITION_PROFIT);
}
return profit;
}

void close_operation(){
double profit=total_Profit();
if(profit>THRESHOLD){
//CLOSE OPERATION
for(int i=0;i<PositionsTotal();i++){
ulong ticket=PositionGetTicket(i);
PositionSelectByTicket(ticket);
trade.PositionClose(ticket);
}

}
}


int OnInit()
  {
 
MACD_HNDLE=iMACD(_Symbol,_Period,24,52,9,PRICE_CLOSE);
IMA_HANDLE=iMA(_Symbol,_Period,50,0,MODE_EMA,PRICE_CLOSE);
IMA_HANDLE2=iMA(_Symbol,_Period,14,0,MODE_EMA,PRICE_CLOSE);
heiken_Ashi=iCustom(_Symbol,_Period,"Examples\\Heiken_Ashi.ex5");
ArraySetAsSeries(MACD_ARRAY,true);
ArraySetAsSeries(MACD_SIGNL,true);
ArraySetAsSeries(IMA_HANDLE_ARRAY,true);
ArraySetAsSeries(IMA_HANDLE2_ARRAY,true);

ArraySetAsSeries(priceinformation,true);

double profits;
  trade.SetExpertMagicNumber(magicnumber);
  for(int i=PositionsTotal()-1;i>=0;i--){
  
  ulong positionticket=PositionGetTicket(i);
  int posmagic=PositionGetTicket(POSITION_MAGIC);
  ulong posHistory=HistoryOrderSelect(positionticket);
  Print(__FUNCTION__,">pos #",positionticket,"has magicnumber",posmagic,"...");
  
  if(posmagic==magicnumber){
  double posProfit=PositionGetDouble(POSITION_PROFIT);
  double posSwap=PositionGetDouble(POSITION_SWAP);
  profits=posProfit+posSwap;
  
  }
  }

   return(INIT_SUCCEEDED);
  }
  

void OnDeinit(const int reason)
  {

   EventKillTimer();
   
  }


void OnTick()
  {



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
if(dayprof>=dailytp){

ExpertRemove();
SendMail("Expert has been stopped remember to restart tomorrow",email);
SendNotification("PROFIT REACHED,EXPERT HAS STOPED TRADING TODAY, MAKE SURE TO RESTART TOMORROW");
Print("profit reached");
}

}
}

if(PositionsTotal()>0)return;
int currentbars=iBars(_Symbol,_Period);
static int prevbars=0;
if(prevbars==currentbars)return;
prevbars=currentbars;



Comment("****CDK SAVAGE DAILY TARGET EA****");
//if(dailytarget());
MqlTradeRequest request;
MqlTradeResult result;
ZeroMemory(request);


CopyBuffer(MACD_HNDLE,0,1,4,MACD_ARRAY);
CopyBuffer(MACD_HNDLE,1,1,4,MACD_SIGNL);

CopyBuffer(IMA_HANDLE,0,0,3,IMA_HANDLE_ARRAY);
CopyBuffer(IMA_HANDLE2,0,1,3,IMA_HANDLE2_ARRAY);

if(PositionSelectByTicket(trade_ticket)==false){

trade_ticket=0;
}


if(isTradeClosedOnBar()==true&&time_flag==true&&trade_ticket<=0&&totalpos(POSITION_TYPE_SELL)==0&&MACD_SIGNL[1]<0&&IMA_HANDLE_ARRAY[1]>IMA_HANDLE2_ARRAY[1]&&IMA_HANDLE2_ARRAY[0]<IMA_HANDLE_ARRAY[0]&&MACD_SIGNL[1]>MACD_ARRAY[1]){
Comment("SELLING");
//Alert("ENTERING SELL");





 
double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
//trade.Sell(0.2,_Symbol,Bid,Bid+4000*_Point,Bid-5000*_Point,"SELL");

//trade_ticket=trade.ResultOrder();

time_flag=false;
EventSetTimer(PeriodSeconds(PERIOD_CURRENT)*45);
request.action=TRADE_ACTION_DEAL;
request.type=ORDER_TYPE_SELL;
openTimeSell=iTime(_Symbol,_Period,0);
request.symbol=_Symbol;
request.volume=0.20;
request.type_filling=ORDER_FILLING_FOK;
request.price=SymbolInfoDouble(_Symbol,SYMBOL_BID);

request.tp=Bid-(takeprofit*_Point);
request.sl=Bid+(stoploss*_Point);
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

void OnTimer()
  {
//---
time_flag=true;
EventKillTimer();
   
  }

void OnTrade()
  {

   
  }

void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {

   
  }

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {

   
  }

void OnBookEvent(const string &symbol)
  {
   
  }


int totalpos(ENUM_POSITION_TYPE pos_type){
int totalType_pos=0;
for(int i=PositionsTotal()-1;i>=0;i--){
trade_ticket=PositionGetTicket(i);
if(trade_ticket>0){
if(PositionSelectByTicket(trade_ticket)){
if(PositionGetString(POSITION_COMMENT)==_Symbol){
if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL&&pos_type==POSITION_TYPE_SELL){

totalType_pos++;
}
}

}
}

}
return (totalType_pos);

}


bool isTradeClosedOnBar(){

HistorySelect(currentBarTime,TimeCurrent());
for(int i=HistoryDealsTotal()-1;i>=0;i--){
ulong myTicket=HistoryDealGetTicket(i);
if(HistoryDealGetInteger(myTicket,DEAL_ENTRY)==DEAL_ENTRY_OUT){
return true;
}
}
return true;
}


