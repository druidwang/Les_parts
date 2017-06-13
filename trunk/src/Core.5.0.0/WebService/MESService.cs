using System.Web.Services;
using com.Sconit.Service;
using com.Sconit.Entity;
using System.Collections.Generic;
using com.Sconit.Service.SI.MES;

namespace com.Sconit.WebService
{
    [WebService(Namespace = "http://com.Sconit.WebService.MESService/")]
    public class MESService : BaseWebService
    {
        private IMESServicesMgr mesServicesMgr
        {
            get
            {
                return GetService<IMESServicesMgr>();
            }
        }

        [WebMethod]
        public string CreateHu(string CustomerCode, string CustomerName, string LotNo, string Item, string ItemDesc, string ManufactureDate, string Manufacturer, string OrderNo, string Uom, decimal UC, decimal Qty, string CreateUser, string CreateDate, string Printer)
        {
            SecurityContextHolder.Set(securityMgr.GetUser("Monitor"));
            return mesServicesMgr.CreateHu(CustomerCode, CustomerName, LotNo, Item, ItemDesc, ManufactureDate, Manufacturer, OrderNo, Uom, UC, Qty, CreateUser, CreateDate, Printer);
        }

        [WebMethod]
        public string CreatePallet(List<string> BoxNos, string BoxCount, string Printer, string CreateUser, string CreateDate)
        {
            SecurityContextHolder.Set(securityMgr.GetUser("Monitor"));
            return mesServicesMgr.CreatePallet(BoxNos, BoxCount, Printer, CreateUser, CreateDate);
        }

        [WebMethod]
        public Entity.SI.MES.InventoryResponse GetInventory(Entity.SI.MES.InventoryRequest request)
        {
            SecurityContextHolder.Set(securityMgr.GetUser("Monitor"));
            return mesServicesMgr.GetInventory(request);
        }
    }
}
