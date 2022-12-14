//+------------------------------------------------------------------+
//|                                                      MACross.mq4 |
//|                           Copyright 2022 Tanay AYITMAZ September |
//|                                        https://www.chainance.net |
//+------------------------------------------------------------------+
#property copyright   "Tanay AYITMAZ 2022 September"                                     
#property version     "1.00"                                                             
#property description "This Expert Advisor MA Cross Strategy." 
#property link        "https://www.chainance.net"
#property strict

#define MAGICVAL 123456789

//Dış Parametreler
extern int MAShort=13; //Moving Average Short Value
extern int MALong=21;  //Moving Average Long Value
extern int OrderNumber=1; // Order Number 
extern double LotValue=0.50; //Lot Value of Per Operation
extern double FarkMin=15;
extern double FarkMax=25;
extern double FiyatAraligi=300;
extern double TakipEt=100;

//İç Parametreler
double HOKisaDeger;
double HOUzunDeger;
double SatisSayi;
double AlisSayi;
double ZararKes=200;
double pSL=0;
int    Digit;

int ToplamEmir,Value,Bilet;

int OnInit()
  {
   Digit=(int)MarketInfo(Symbol(),MODE_DIGITS);
   Print("Digit Tanımlanıyor : ",Digit," - Point Tanımlanıyor : ",DoubleToStr(Point));
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
  {
   for(int i=ObjectsTotal()-1; i>=0; i--)
     {
      string name=ObjectName(i);
      if(StringFind(name,"nk_")>=0) ObjectDelete(name);
     }
  }
  
double IslemSay(int p_OrderType)
{
  int count_=0;
  for(Value=0;Value<OrdersTotal();Value++)
    {
      if(!OrderSelect(Value,SELECT_BY_POS)) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICVAL) 
        {
          if (p_OrderType==0 && OrderType()==OP_BUY) count_++;
          if (p_OrderType==1 && OrderType()==OP_SELL) count_++;
        }
    }
  return(count_);
}

double IslemSayTumu()
{
  int count_=0;
  for(Value=0;Value<OrdersTotal();Value++)
    {
      if(!OrderSelect(Value,SELECT_BY_POS)) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICVAL) 
        { count_++; }
    }
  return(count_);
}

void AlimKapat()
  {
    ToplamEmir=OrdersTotal();
    for(Value=0;Value<ToplamEmir;Value++)
      {
        if(!OrderSelect(Value,SELECT_BY_POS)) continue;
        if(OrderType()==OP_BUY && Symbol()==OrderSymbol() && NormalizeDouble(HOUzunDeger,Digit) > NormalizeDouble(HOKisaDeger,Digit) 
           //&& NormalizeDouble(HOUzunDeger-HOKisaDeger,Digit)>=FarkMin*Point && NormalizeDouble(HOUzunDeger-HOKisaDeger,Digit)<=FarkMax*Point
           )
          {
            if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),2,Yellow))
              {Print("Alım (Long) İşlemi Kapatıldı. Kapama Fiyatı : ",OrderClosePrice());
              return;
              } else Print("Alım Kapama İşlemi Gerçekleşmedi. Geçerli Hata : ",GetLastError());
          }
      }
  }
  
void SatimKapat()
  {
    ToplamEmir=OrdersTotal();
    for(Value=0;Value<ToplamEmir;Value++)
      {
        if(!OrderSelect(Value,SELECT_BY_POS)) continue;        
        if(OrderType()==OP_SELL && Symbol()==OrderSymbol() && NormalizeDouble(HOKisaDeger,Digit) > NormalizeDouble(HOUzunDeger,Digit) 
           //&& NormalizeDouble(HOKisaDeger-HOUzunDeger,Digit)>=FarkMin*Point && NormalizeDouble(HOKisaDeger-HOUzunDeger,Digit)<=FarkMax*Point 
           )
          {
            if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),2,Yellow))
              {Print("Satım (Short) İşlemi Kapatıldı. Kapama Fiyatı : ",OrderClosePrice()); 
              return;
              } else Print("Satım Kapama İşlemi Gerçekleşmedi. Geçerli Hata : ",GetLastError());
          }
      }
  }
  
 void TakipEdenZarar() 
{
   double SL_Trailing;
   for (int pos_sl = 0; pos_sl < OrdersTotal(); pos_sl++) 
   {
      if (OrderSelect(pos_sl, SELECT_BY_POS) != FALSE) 
      {
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICVAL) 
          {
            if (OrderType() == OP_BUY) 
              {
                SL_Trailing = Bid - Point * TakipEt;
                if (OrderStopLoss() < SL_Trailing && OrderOpenPrice() < SL_Trailing) 
                  TakipEdenZararGuncelle(SL_Trailing, OrderTicket()); 
               }
               if (OrderType() == OP_SELL)
               {
                 SL_Trailing = Ask + Point * TakipEt;
                 if ((OrderOpenPrice()-Ask) > (Point*TakipEt))
                   {
                     if((OrderStopLoss()>SL_Trailing) || (OrderStopLoss()==0))
                       {TakipEdenZararGuncelle(SL_Trailing, OrderTicket());}
                   }
               }
          }
      }
   }
}

void TakipEdenZararGuncelle(double p_Price, int p_Ticket) 
{
   if (OrderModify(p_Ticket, OrderOpenPrice(), p_Price, OrderTakeProfit(), 0, Red) == True) 
   {
     if (OrderType()==OP_BUY) Print("Alım Güncellendi : ",p_Price);
     if (OrderType()==OP_SELL) Print("Satım Güncellendi : ",p_Price);
   } else
   {
   } 
}

void SetText(string pName, int pX)
  {
    ObjectDelete(0,pName); 
    ObjectCreate(pName,OBJ_LABEL,0,0,0);
    ObjectSet(pName,OBJPROP_CORNER,True);
    ObjectSet(pName,OBJPROP_XDISTANCE,50);
    ObjectSet(pName,OBJPROP_YDISTANCE,pX);
  }

void BilgiYaz()
  {
    SetText("nk_HOUzun",300);
    ObjectSetText("nk_HOUzun","Uzun Ortalama : "+IntegerToString(MALong)+" "+ DoubleToStr(HOUzunDeger,Digit),8,"Tahoma Narrow",clrGold);
    SetText("nk_HOKisa",320);
    ObjectSetText("nk_HOKisa","Kısa Ortalama : "+IntegerToString(MAShort)+" "+ DoubleToStr(HOKisaDeger,Digit),8,"Tahoma Narrow",clrGold);
    if (NormalizeDouble(HOKisaDeger,Digit) > NormalizeDouble(HOUzunDeger,Digit))
      {
        SetText("nk_HOKisaDeger",340);
        ObjectSetText("nk_HOKisaDeger","Long : "+ DoubleToStr(HOKisaDeger-HOUzunDeger,Digit),8,"Tahoma Narrow",clrWhite);
      } 
    if (NormalizeDouble(HOUzunDeger,Digit) > NormalizeDouble(HOKisaDeger,Digit))
      {
        SetText("nk_HOUzunDeger",360);
        ObjectSetText("nk_HOUzunDeger","Short : "+ DoubleToStr(HOUzunDeger-HOKisaDeger,Digit),8,"Tahoma Narrow",clrWhite);
      } 
  }
    
void OnTick()
{
  HOKisaDeger=iMA(Symbol(),PERIOD_CURRENT,MAShort,0,MODE_SMMA,PRICE_TYPICAL,0);
  HOUzunDeger=iMA(Symbol(),PERIOD_CURRENT,MALong,0,MODE_SMMA,PRICE_TYPICAL,0); 
  
  BilgiYaz();  
  AlisSayi=0;
  SatisSayi=0;
  if (TakipEt != 0) TakipEdenZarar();   
  AlimKapat();
  SatimKapat();  
  
  //Fiyat Aralığı Kontrolü
  for(Value=0; Value<OrdersTotal(); Value++)
    {
      if(!OrderSelect(Value,SELECT_BY_POS)) continue;      
      //Alım Fiyat Aralığı
      if(FiyatAraligi>0)
        {
          if(OrderType()==OP_BUY && (NormalizeDouble(HOKisaDeger,Digit) > NormalizeDouble(HOUzunDeger,Digit)) && Symbol()==OrderSymbol()) 
            if (OrderMagicNumber()==MAGICVAL)
              {
                if((OrderOpenPrice()+FiyatAraligi*Point)>Ask) 
                  {Print("Fiyat Aralık Kontrolü Yapılıyor : ",DoubleToStr(OrderOpenPrice()+FiyatAraligi*Point)," - Alış Fiyatı : ",DoubleToStr(Ask,Digit));
                  return;}
              }
        }
      //Satım Fiyat Aralığı
      if(FiyatAraligi>0)
        {
          if(OrderType()==OP_SELL && (NormalizeDouble(HOUzunDeger,Digit) > NormalizeDouble(HOKisaDeger,Digit)) && Symbol()==OrderSymbol()) 
            if (OrderMagicNumber()==MAGICVAL)
              {
                if((OrderOpenPrice()-FiyatAraligi*Point)<Bid) 
                  {Print("Fiyat Aralık Kontrolü Yapılıyor : ",DoubleToStr(OrderOpenPrice()-FiyatAraligi*Point)," - Satış Fiyatı : ",DoubleToStr(Bid,Digit));
                  return;}
              }
        }         
    }
    
  if(IslemSayTumu()<OrderNumber)
  {  
  
      ToplamEmir=OrdersTotal();
      for(Value=0; Value<ToplamEmir; Value++)
        {
         if(!OrderSelect(Value,SELECT_BY_POS)) continue;
         if (OrderType()==OP_BUY)  AlisSayi++;
         if (OrderType()==OP_SELL) SatisSayi++;
        }
        
         //Long
         if (NormalizeDouble(HOKisaDeger,Digit) > NormalizeDouble(HOUzunDeger,Digit))
           {
             if (IslemSay(OP_SELL)>0) return; 
             if (AlisSayi==0)
               {
                 if (NormalizeDouble(HOKisaDeger-HOUzunDeger,Digit)>=FarkMin*Point && NormalizeDouble(HOKisaDeger-HOUzunDeger,Digit)<=FarkMax*Point && NormalizeDouble(HOKisaDeger<Ask,Digit))
                   {
                     //pSL=(Ask-ZararKes*Point);
                     Print("Alım İşlemi Talebi Yapılıyor. Fiyat :",Ask," / Toplam Emir Sayısı : ",ToplamEmir);
                     Bilet=OrderSend(Symbol(),OP_BUY,LotValue,Ask,2,pSL,0,"Tanay.MACross_Exp_Adv Long",MAGICVAL,0,Green);
                     if(Bilet>0)
                       {
                         if(OrderSelect(Bilet,SELECT_BY_TICKET,MODE_TRADES))
                           { Print("Alım (Long) İşlemi Tamamlandı. Alım Fiyatı : ",OrderOpenPrice());}
                       } else Print("Alım İşlemi Gerçekleşmedi. Geçerli Hata : ",GetLastError());
                     return;
                   }
               }
             if (AlisSayi>0)
               {
                 if (NormalizeDouble(HOKisaDeger-HOUzunDeger,Digit)>=FarkMin*Point && NormalizeDouble(HOKisaDeger-HOUzunDeger,Digit)<=FarkMax*Point && NormalizeDouble(HOKisaDeger<Ask,Digit))
                   {
                     Print("Alım İşlemi Talebi Yapılıyor. Fiyat :",Ask," / Toplam Emir Sayısı : ",ToplamEmir);
                     Bilet=OrderSend(Symbol(),OP_BUY,LotValue,Ask,2,0,0,"Tanay.MACross_Exp_Adv Long",MAGICVAL,0,Green);
                     if(Bilet>0)
                       {
                         if(OrderSelect(Bilet,SELECT_BY_TICKET,MODE_TRADES))
                           { Print("2 Alım (Long) İşlemi Tamamlandı. Alım Fiyatı : ",OrderOpenPrice()); }
                       } else Print("Alım İşlemi Gerçekleşmedi. Geçerli Hata : ",GetLastError());
                     return;               
                   }
               }
           }
         
         //Short
         if (NormalizeDouble(HOUzunDeger,Digit) > NormalizeDouble(HOKisaDeger,Digit))
           {
             if (IslemSay(OP_BUY)>0) return; 
             if (SatisSayi==0)
               {
                 //Print("Short İşlemi İçin Algoritma Kontrol Ediliyor",DoubleToStr(HOUzunDeger-HOKisaDeger,Digit)," - ",DoubleToStr(FarkMin*Point,Digit)," - ",DoubleToStr(FarkMax*Point,Digit)," - ",DoubleToStr(Bid,Digit));
                 if (NormalizeDouble(HOUzunDeger-HOKisaDeger,Digit)>=FarkMin*Point && NormalizeDouble(HOUzunDeger-HOKisaDeger,Digit)<=FarkMax*Point && NormalizeDouble(HOUzunDeger>Bid,Digit))
                   {
                     //Print("Short İşlemi İçin Algoritma Kontrol Ediliyor",DoubleToStr(HOUzunDeger-HOKisaDeger,Digit)," - ",DoubleToStr(FarkMin*Point,Digit)," - ",DoubleToStr(FarkMax*Point,Digit)," - ",DoubleToStr(Bid,Digit));
                     //pSL=(Bid+(ZararKes*Point));
                     Print("Satım İşlemi Talebi Yapılıyor. Fiyat :",Bid," / Toplam Emir Sayısı : ",ToplamEmir);
                     Bilet=OrderSend(Symbol(),OP_SELL,LotValue,Bid,2,pSL,0,"Tanay.MACross_Exp_Adv Short",MAGICVAL,0,Green);
                     if(Bilet>0)
                       {
                         if(OrderSelect(Bilet,SELECT_BY_TICKET,MODE_TRADES))
                           {
                             Print("Satım (Short) İşlemi Tamamlandı. Alım Fiyatı : ",OrderOpenPrice());
                           }
                       } else Print("Satım İşlemi Gerçekleşmedi. Geçerli Hata : ",GetLastError());
                     return;
                   }
               }
             if (SatisSayi>0)
               {
                 if (NormalizeDouble(HOUzunDeger-HOKisaDeger,Digit)>=FarkMin*Point && NormalizeDouble(HOUzunDeger-HOKisaDeger,Digit)<=FarkMax*Point && NormalizeDouble(HOUzunDeger>Bid,Digit))
                   {
                     Print("Satım İşlemi Talebi Yapılıyor. Fiyat :",Bid," / Toplam Emir Sayısı : ",ToplamEmir);
                     Bilet=OrderSend(Symbol(),OP_SELL,LotValue,Bid,2,0,0,"Tanay.MACross_Exp_Adv Short",MAGICVAL,0,Green);
                     if(Bilet>0)
                       {
                         if(OrderSelect(Bilet,SELECT_BY_TICKET,MODE_TRADES))
                           {
                             Print("2 Satım (Short) İşlemi Tamamlandı. Alım Fiyatı : ",OrderOpenPrice());
                           }
                       } else Print("Satım İşlemi Gerçekleşmedi. Geçerli Hata : ",GetLastError());
                     return;
                   }
               }
           }
  }
  
  // Spike Kontrol işlem yönüne göre 100pips yukarısı hareketlerde işleme girmeyecek
}
