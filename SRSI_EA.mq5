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
#include <Trade\PositionInfo.mqh> //подключаем библиотеку для получения информации о позициях

input int RSI_per=21;    //период RSI
input int RSI_HiLevel=80;     //верхний уровень RSI
input int RSI_LoLevel=20;     //нижний уровень RSI
input int Stoh_Kper = 8;    //K период Stohastic
input int Stoh_Dper = 5;    //D период Stohastic
input int Stoh_Slowing=5;    //Slowing Stohastic
input int Stoh_HiLevel=70;     //верхний уровень Stohastic
input int Stoh_LoLevel=30;     //нижний уровень Stohastic
input bool StaticLot=true;    //Лот статичный
input double Lot=0.01;        //размер лота
input int PercentProfit=2;    //процент профита который возьмет робот

//---- indicator buffers
double      RSI[];                // массив для индикатора iRSI
double      Stochastic[];        // массив для MAIN_LINE индикатора iStochastic
//---- handles for indicators
int         RSI_handle;           // указатель на индикатор iRSI
int         Stochastic_handle;           // указатель на индикатор iStochastic

double   RealLot;
double balanse;
double profit;

//---
CAccountInfo   myaccount_info;      //действия по аккаунту
CTrade         myaccount_trade;     //действия по торговле
CPositionInfo  myaccount_position; //объект для получения информации о позициях
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- создание указателя на объект - индикатор iRSI
   RSI_handle=iRSI(NULL,0,RSI_per,PRICE_CLOSE);
//--- если произошла ошибка при создании объекта, то выводим сообщение
   if(RSI_handle<0)
     {
      Print("Объект iRSI не создан: Ошибка исполнения = ",GetLastError());
      //--- принудительное завершение программы
      return(-1);
     }
//--- создание указателя на объект - индикатор iStochastic
   Stochastic_handle=iStochastic(NULL,0,Stoh_Kper,Stoh_Dper,Stoh_Slowing,MODE_SMA,STO_LOWHIGH);
//--- если произошла ошибка при создании объекта, то выводим сообщение
   if(Stochastic_handle<0)
     {
      Print("Объект iStochastic не создан: Ошибка исполнения = ",GetLastError());
      //--- принудительное завершение программы
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
//--- заполнение массива RSI[] текущими значениями индикатора iRSI
//--- задаём порядок индексации массива как в таймсерии
//--- если произошла ошибка, то прекращаем выполнение дальнейших операций
   if(CopyBuffer(RSI_handle,0,0,100,RSI)<=0) return;
   ArraySetAsSeries(RSI,true);

//--- задаём порядок индексации массивов как в таймсерии
//--- если произошла ошибка, то прекращаем выполнение дальнейших операций
//--- заполнение объявленных массивов текущими значениями из всех индикаторных буферов
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

//--- Проверяем новый это бар и разрешение на торговлю
   if(isNewBar() && myaccount_info.TradeAllowed())
     {
      if(PositionSelect(_Symbol))
        {
         if(((profit/balanse)*100)>PercentProfit)
           {
            Alert("Закрыт по профиту "+profit);
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
//| Возвращает true, если появился новый бар для пары символ/период  |
//+------------------------------------------------------------------+
bool isNewBar()
  {
//--- в статической переменной будем помнить время открытия последнего бара
   static datetime last_time=0;
//--- текущее время
   datetime lastbar_time=SeriesInfoInteger(Symbol(),PERIOD_CURRENT,SERIES_LASTBAR_DATE);

//--- если это первый вызов функции
   if(last_time==0)
     {
      //--- установим время и выйдем 
      last_time=lastbar_time;
      return(false);
     }

//--- если время отличается
   if(last_time!=lastbar_time)
     {
      //--- запомним время и вернем true
      last_time=lastbar_time;
      return(true);
     }
//--- дошли до этого места - значит бар не новый, вернем false
   return(false);
  }
//+------------------------------------------------------------------+
