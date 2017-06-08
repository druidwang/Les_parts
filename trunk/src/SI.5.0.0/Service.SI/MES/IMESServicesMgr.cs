using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace com.Sconit.Service.SI.MES
{
    public interface IMESServicesMgr
    {
        string CreateHu(string CustomerCode, string CustomerName, string LotNo, string Item, string ItemDesc, string ManufactureDate, string Manufacturer, string OrderNo, string Uom, decimal UC, decimal Qty, string CreateUser, string CreateDate, string Printer);

        string CreatePallet(List<string> BoxNos, string BoxCount, string Printer, string CreateUser, string CreateDate);
    }
}	