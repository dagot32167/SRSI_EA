//+------------------------------------------------------------------+
//|                                                      SRSI_EA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "3.00"

#include <Trade\AccountInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh> //���������� ���������� ��� ��������� ���������� � ��������

input int RSI_per=21;    //������ RSI
input int RSI_HiLevel=80;     //������� ������� RSI
input int RSI_LoLevel=20;     //������ ������� RSI
input int Stoh_Kper = 8;    //K ������ Stohastic
input int Stoh_Dper = 5;    //D ������ Stohastic
input int Stoh_Slowing=5;    //Slowing Stohastic
input int Stoh_HiLevel=70;     //������� ������� Stohastic
input int Stoh_LoLevel=30;     //������ ������� Stohastic
input bool StaticLot=true;    //��� ���������
input double Lot=0.01;        //������ ����
input int PercentProfit=2;    //������� ������� ������� ������� �����

//---- indicator buffers
double      RSI[];                // ������ ��� ���������� iRSI
double      Stochastic[];        // ������ ��� MAIN_LINE ���������� iStochastic
//---- handles for indicators
int         RSI_handle;           // ��������� �� ��������� iRSI
int         Stochastic_handle;           // ��������� �� ��������� iStochastic

double   RealLot;
double balanse;
double profit;

//---
CAccountInfo   myaccount_info;      //�������� �� ��������
CTrade         myaccount_trade;     //�������� �� ��������
CPositionInfo  myaccount_position; //������ ��� ��������� ���������� � ��������
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- �������� ��������� �� ������ - ��������� iRSI
   RSI_handle=iRSI(NULL,0,RSI_per,PRICE_CLOSE);
//--- ���� ��������� ������ ��� �������� �������, �� ������� ���������
   if(RSI_handle<0)
     {
      Print("������ iRSI �� ������: ������ ���������� = ",GetLastError());
      //--- �������������� ���������� ���������
      return(-1);
     }
//--- �������� ��������� �� ������ - ��������� iStochastic
   Stochastic_handle=iStochastic(NULL,0,Stoh_Kper,Stoh_Dper,Stoh_Slowing,MODE_SMA,STO_LOWHIGH);
//--- ���� ��������� ������ ��� �������� �������, �� ������� ���������
   if(Stochastic_handle<0)
     {
      Print("������ iStochastic �� ������: ������ ���������� = ",GetLastError());
      //--- �������������� ���������� ���������
      return(-1);
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- ���������� ������� RSI[] �������� ���������� ���������� iRSI
//--- ����� ������� ���������� ������� ��� � ���������
//--- ���� ��������� ������, �� ���������� ���������� ���������� ��������
   if(CopyBuffer(RSI_handle,0,0,100,RSI)<=0) return;
   ArraySetAsSeries(RSI,true);

//--- ����� ������� ���������� �������� ��� � ���������
//--- ���� ��������� ������, �� ���������� ���������� ���������� ��������
//--- ���������� ����������� �������� �������� ���������� �� ���� ������������ �������
   if(CopyBuffer(Stochastic_handle,MAIN_LINE,0,100,Stochastic)<=0) return;
   ArraySetAsSeries(Stochastic,true);

   balanse= myaccount_info.Balance();
   profit = PositionGetDouble(POSITION_PROFIT);

   if(!StaticLot)
     {
      RealLot=NormalizeDouble(((myaccount_info.Equity()/5000)/100),2);
     }
   else
     {
      RealLot=Lot;
     }

//--- ��������� ����� ��� ��� � ���������� �� ��������
   if(isNewBar() && myaccount_info.TradeAllowed())
     {
      if(PositionSelect(_Symbol))
        {
         if(((profit/balanse)*100)>PercentProfit)
           {
            Alert("������ �� ������� "+profit);
            Print(((profit/balanse)*100));
            myaccount_trade.PositionClose(Symbol());
           }
        }

      if(RSI[1]>RSI_HiLevel && Stochastic[1]>Stoh_HiLevel)
        {
         myaccount_trade.Sell(RealLot,Symbol());
        }
      if(RSI[1]<RSI_LoLevel && Stochastic[1]<Stoh_LoLevel)
        {
         myaccount_trade.Buy(RealLot,Symbol());
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ���������� true, ���� �������� ����� ��� ��� ���� ������/������  |
//+------------------------------------------------------------------+
bool isNewBar()
  {
//--- � ����������� ���������� ����� ������� ����� �������� ���������� ����
   static datetime last_time=0;
//--- ������� �����
   datetime lastbar_time=SeriesInfoInteger(Symbol(),PERIOD_CURRENT,SERIES_LASTBAR_DATE);

//--- ���� ��� ������ ����� �������
   if(last_time==0)
     {
      //--- ��������� ����� � ������ 
      last_time=lastbar_time;
      return(false);
     }

//--- ���� ����� ����������
   if(last_time!=lastbar_time)
     {
      //--- �������� ����� � ������ true
      last_time=lastbar_time;
      return(true);
     }
//--- ����� �� ����� ����� - ������ ��� �� �����, ������ false
   return(false);
  }
//+------------------------------------------------------------------+
