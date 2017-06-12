using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Service.SI.MES;

namespace com.Sconit.Service.SI.Impl.MES
{
    public class MESServicesMgrImpl : IMESServicesMgr
    {
        public string CreateHu(string CustomerCode, string CustomerName, string LotNo, string Item, string ItemDesc, string ManufactureDate, string Manufacturer, string OrderNo, string Uom, decimal UC, decimal Qty, string CreateUser, string CreateDate, string Printer)
        {
            //throw new NotImplementedException();
            var hu = "HU00000001";
            return hu;
        }


        public string CreatePallet(List<string> BoxNos, string BoxCount, string Printer, string CreateUser, string CreateDate)
        {
            var kp = "KP00000001";
            return kp;
        }

    

        public Entity.SI.MES.InventoryResponse  GetInventory(Entity.SI.MES.InventoryRequest request)
        {
            var response = new Entity.SI.MES.InventoryResponse();
            response.RequestId = request.RequestId;
            response.IsEnd = false;
            response.Inventorys = new List<Entity.SI.MES.Inventory>();
            response.Inventorys.Add(new Entity.SI.MES.Inventory { BarCode = "HU00000001", BatchNo = "1111111", FactoryCode = "", MaterialCode = "Item1", Quantity = 10, Type = 1, WarehouseCode = "10079" });
            return response;
        }
    }
}	