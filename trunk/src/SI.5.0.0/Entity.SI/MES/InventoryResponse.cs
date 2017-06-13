using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace com.Sconit.Entity.SI.MES
{
    public class InventoryResponse
    {
        public string RequestId { get; set; }

        public bool IsEnd { get; set; }

        public List<Inventory> Inventorys { get; set; }

    }

    public class Inventory
    { 
        public string MaterialCode { get; set; }
        public string WarehouseCode { get; set; }
        public string FactoryCode { get; set; }
        public string BarCode { get; set; }
        public string BatchNo { get; set; }
        public decimal Quantity { get; set; }
        public int Type{ get; set; }
    }
}
