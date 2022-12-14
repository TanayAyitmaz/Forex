//+------------------------------------------------------------------+
//|                                                   martingale.mq5 |
//|                                                    Tanay AYITMAZ |
//|                                        https://www.chainance.net |
//+------------------------------------------------------------------+
#property copyright "Tanay AYITMAZ"
#property link      "https://www.chainance.net"
#property version   "1.00"

//- input parameters
input int    MaxOperation   = 5;       //Maksimum İşlem
input double StartLot       = 0.01;    //Başlangıç Lotu
input int    Multiplier     = 2;       //Lot Çarpanı
input int    OperationRange = 100;     //İşlem Aralığı
input double StopLoss       = 0;       //Zarar Kes
input double TakeProfit     = 900;     //Kar Al

//- EA Parameters
int MagicNumber= 230304;

//- Internal Values
double 
  RSIValue  , RSIValueArray[]  , RSI, 
  SMA50Value, SMA50ValueArray[], SMA50,
  LotArray[];

void LotSistemi()
{
  double Lots=0;
  ArrayResize(LotArray, MaxOperation);
  for (int i=0; i < MaxOperation; i++)
  {
    if (i == 0) 
    { 
      Lots = StartLot;
      LotArray[i] = Lots;
      Print("İlk İşlem : ",Lots);
    }
    else
    {
      Lots = Lots * Multiplier;
      LotArray[i] = Lots;
      Print((i+1)+". İşlem :",Lots);
    }
  }
}

//- Functions
void Etiket(const string name,const int x,const int y, const string str,const color clr, const int fontsize, const int chartid=0)
{
   ObjectCreate    (0,name,OBJ_LABEL,chartid,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString (0,name,OBJPROP_TEXT,str);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontsize);
}

//- İşlemleri Sayar (Short & Long)
double IslemSay(long pOrderType)
{
  int IslemSayisi=0;
  for (int i=0; i < PositionsTotal(); i++)
  {      
    if ( PositionSelectByTicket( PositionGetTicket(i) ) > 0 )
    {
      if ( PositionGetString(POSITION_SYMBOL) == Symbol() )
      {
        if ( pOrderType==0 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)  IslemSayisi++;
        if ( pOrderType==1 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) IslemSayisi++;
      }
    }
  }
  return(IslemSayisi);
}

//- En Yüksek Satım Fiyatını Bulur
double SatimFiyatiBul()
{
  double SatimFiyati=0;
  for(int i=0; i < PositionsTotal(); i++)
  {      
    if ( PositionSelectByTicket( PositionGetTicket(i) ) > 0 )
    {
      if ( PositionGetString(POSITION_SYMBOL) == Symbol() )
      {
        if (PositionGetDouble(POSITION_PRICE_OPEN) > SatimFiyati)
        {
          SatimFiyati = PositionGetDouble(POSITION_PRICE_OPEN);
          //Print("Satım Fiyat :"+SatimFiyati+" - "+NormalizeDouble((SatimFiyati + OperationRange*_Point),_Digits)+" - "+NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits));
        }               
      }
    }
  }
  return(SatimFiyati + OperationRange*_Point);
}

//- En Düşük Alım Fiyatını Bulur
double AlimFiyatiBul()
{
  double AlimFiyati=9999;
  for(int i=0; i < PositionsTotal(); i++)
  {      
    if ( PositionSelectByTicket( PositionGetTicket(i) ) > 0 )
    {
      if ( PositionGetString(POSITION_SYMBOL) == Symbol() && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY )
      {
        if (PositionGetDouble(POSITION_PRICE_OPEN) < AlimFiyati)
        {
          AlimFiyati = PositionGetDouble(POSITION_PRICE_OPEN);
          //Print("Alım Fiyat :"+AlimFiyati+" - "+NormalizeDouble((AlimFiyati - OperationRange*_Point),_Digits)+" - "+NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits));
        }               
      }
    }
  }
  return(AlimFiyati - OperationRange*_Point);
}

int OnInit()
  {
   LotSistemi();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   
  }

void OnTick()  
  {
   int ToplamIslem=0;

   //- SMA 50 H4 Değeri Standart Trend takibi için kullanıyoruz
   SMA50Value =iMA(Symbol(),PERIOD_H4,50,0,MODE_SMA,PRICE_CLOSE);
   ArraySetAsSeries(SMA50ValueArray,true);
   CopyBuffer(SMA50Value,0,0,3,SMA50ValueArray);
   SMA50 = NormalizeDouble(SMA50ValueArray[0],5);
   
   //- RSI Değeri Alınır (ilk işleme giriş için kullanılacaktır)
   RSIValue=iRSI(Symbol(),PERIOD_CURRENT,9,PRICE_CLOSE);
   ArraySetAsSeries(RSIValueArray,true);
   CopyBuffer(RSIValue,0,0,2,RSIValueArray);
   RSI = NormalizeDouble(RSIValueArray[0],2); 
   
   //- *Satım İşlemine başlıyoruz*

   // Alım İşlemi Yoksa
   if (IslemSay(POSITION_TYPE_BUY)==0)
   {
     // Satım İşlemi MaxOperation parametresinden Küçük ve Eşit mi?
     if (IslemSay(POSITION_TYPE_SELL) < MaxOperation)     
     {
       // Fiyat SMA 50 atındaysa
       if (NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits) < SMA50)
       {
         ToplamIslem = IslemSay(POSITION_TYPE_SELL);
         // RSI 9 70 değerinden büyük eşitse Satım İşlemi başlar
         if (RSI >= 70)
         {
           // İlk İşlem
           if ( ToplamIslem == 0 )
           {
             //- Hiç işlemimiz yoksa
             double ExecutionTime   = GetTickCount();
             double ExecutionPeriod = 0;
             MqlTradeRequest request={0};
             request.action =TRADE_ACTION_DEAL;
             request.type_filling = ORDER_FILLING_FOK; // ORDER_FILLING_IOC;                          
             request.magic  =MagicNumber;                   
             request.symbol =Symbol();                       
             request.volume =StartLot;                     
             if (StopLoss == 0)
               {request.sl   =0;} else
               {request.sl   =SymbolInfoDouble(_Symbol,SYMBOL_BID) + StopLoss * _Point;}               
             if (TakeProfit == 0)
               {request.tp     =0;} else
               {request.tp     =SymbolInfoDouble(_Symbol,SYMBOL_BID) - TakeProfit * _Point;}
             request.comment="Short";
             request.type   =ORDER_TYPE_SELL;
             request.price  =SymbolInfoDouble(Symbol(),SYMBOL_BID);
             MqlTradeResult result={0};
             OrderSend(request,result);    
             ExecutionPeriod = GetTickCount() - ExecutionTime; 
             if (result.retcode == 10009)
             {
               Etiket("lbl_ExecutionTime",50,170,"Emir Gönderim Süresi :"+DoubleToString(ExecutionPeriod,2),clrWhite,8);
               Print("İlk Satım İşlemi Tamamlandı. Satım Fiyatı : ",result.price," - Sunucu Dönüş Kodu :",result.retcode);
             } else 
               Print("İlk Satım İşlemi Gerçekleşmedi. Geçerli Hata : ",GetLastError()," - ",result.retcode);                       
           }
         } 
           
         if ( ToplamIslem > 0 )
         {
           //- İlk işlemlerden sonraki işlemler
           if (NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits) > SatimFiyatiBul() )
           {
             double ExecutionTime   = GetTickCount();
             double ExecutionPeriod = 0;
             MqlTradeRequest request={0};
             request.action =TRADE_ACTION_DEAL;
             request.type_filling = ORDER_FILLING_FOK; // ORDER_FILLING_IOC;                          
             request.magic  =MagicNumber;                   
             request.symbol =Symbol();                       
             request.volume =LotArray[ToplamIslem];                     
             if (StopLoss == 0)
               {request.sl   =0;} else
               {request.sl   =SymbolInfoDouble(_Symbol,SYMBOL_BID) + StopLoss * _Point;}               
             if (TakeProfit == 0)
               {request.tp     =0;} else
               {request.tp     =SymbolInfoDouble(_Symbol,SYMBOL_BID) - TakeProfit * _Point;}
             request.comment="Short";
             request.type   =ORDER_TYPE_SELL;
             request.price  =SymbolInfoDouble(Symbol(),SYMBOL_BID);
             MqlTradeResult result={0};
             OrderSend(request,result);    
             ExecutionPeriod = GetTickCount() - ExecutionTime; 
             if (result.retcode == 10009)
             {
               Etiket("lbl_ExecutionTime",50,170,"Emir Gönderim Süresi :"+DoubleToString(ExecutionPeriod,2),clrWhite,8);
               Print( (ToplamIslem+1)+ ". Satım İşlemi Tamamlandı. Satım Fiyatı : ",result.price," - Sunucu Dönüş Kodu :",result.retcode );
             } else 
               Print( (ToplamIslem+1)+ ". Satım İşlemi Gerçekleşmedi. Geçerli Hata : ",GetLastError()," - ",result.retcode );                                    
           }
         }         
       }
     }
   }  
   
   //- Alım İşlemine Başlıyoruz

   // Satım İşlemi Yoksa
   if (IslemSay(POSITION_TYPE_SELL)==0)
   {
     // Satım İşlemi MaxOperation parametresinden Küçük ve Eşit mi?
     if (IslemSay(POSITION_TYPE_BUY) < MaxOperation)     
     {
       // Fiyat SMA 50 üzerindeyse
       if (NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits) > SMA50)
       {
         ToplamIslem = IslemSay(POSITION_TYPE_BUY);
         // RSI 9 70 değerinden büyük eşitse Satım İşlemi başlar
         if (RSI <= 30)
         {
           // İlk İşlem
           if ( ToplamIslem == 0 )
           {
             //- Hiç işlemimiz yoksa
             double ExecutionTime   = GetTickCount();
             double ExecutionPeriod = 0;
             MqlTradeRequest request={0};
             request.action =TRADE_ACTION_DEAL;
             request.type_filling = ORDER_FILLING_FOK; // ORDER_FILLING_IOC;                          
             request.magic  =MagicNumber;                   
             request.symbol =Symbol();                       
             request.volume =StartLot;                     
             if (StopLoss == 0)
               {request.sl   =0;} else
               {request.sl   =SymbolInfoDouble(_Symbol,SYMBOL_ASK) - StopLoss * _Point;}               
             if (TakeProfit == 0)
               {request.tp     =0;} else
               {request.tp     =SymbolInfoDouble(_Symbol,SYMBOL_ASK) + TakeProfit * _Point;}
             request.comment="Short";
             request.type   =ORDER_TYPE_BUY;
             request.price  =SymbolInfoDouble(Symbol(),SYMBOL_ASK);
             MqlTradeResult result={0};
             OrderSend(request,result);    
             ExecutionPeriod = GetTickCount() - ExecutionTime; 
             if (result.retcode == 10009)
             {
               Etiket("lbl_ExecutionTime",50,170,"Emir Gönderim Süresi :"+DoubleToString(ExecutionPeriod,2),clrWhite,8);
               Print("İlk Alım İşlemi Tamamlandı. Alım Fiyatı : ",result.price," - Sunucu Dönüş Kodu :",result.retcode);
             } else 
               Print("İlk Alım İşlemi Gerçekleşmedi. Geçerli Hata : ",GetLastError()," - ",result.retcode);                       
           } 
         }
         
         if ( ToplamIslem > 0 )
         {
           //Print("İlk İşlem Sonrası - Fiyat : "+NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits)+" - "+AlimFiyatiBul() );
           //- İlk işlemlerden sonraki işlemler
           if (NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits) < AlimFiyatiBul() )
           {
             double ExecutionTime   = GetTickCount();
             double ExecutionPeriod = 0;
             MqlTradeRequest request={0};
             request.action =TRADE_ACTION_DEAL;
             request.type_filling = ORDER_FILLING_FOK; // ORDER_FILLING_IOC;                          
             request.magic  =MagicNumber;                   
             request.symbol =Symbol();                       
             request.volume =LotArray[ToplamIslem];                     
             if (StopLoss == 0)
               {request.sl   =0;} else
               {request.sl   =SymbolInfoDouble(_Symbol,SYMBOL_ASK) - StopLoss * _Point;}               
             if (TakeProfit == 0)
               {request.tp     =0;} else
               {request.tp     =SymbolInfoDouble(_Symbol,SYMBOL_ASK) + TakeProfit * _Point;}
             request.comment="Short";
             request.type   =ORDER_TYPE_BUY;
             request.price  =SymbolInfoDouble(Symbol(),SYMBOL_ASK);
             MqlTradeResult result={0};
             OrderSend(request,result);    
             ExecutionPeriod = GetTickCount() - ExecutionTime; 
             if (result.retcode == 10009)
             {
               Etiket("lbl_ExecutionTime",50,170,"Emir Gönderim Süresi :"+DoubleToString(ExecutionPeriod,2),clrWhite,8);
               Print( (ToplamIslem+1)+ ". Alım İşlemi Tamamlandı. Alım Fiyatı : ",result.price," - Sunucu Dönüş Kodu :",result.retcode );
              } else 
               Print( (ToplamIslem+1)+ ". Alım İşlemi Gerçekleşmedi. Geçerli Hata : ",GetLastError()," - ",result.retcode );                                    
           }
         }     
       }
     }           
   }
  }