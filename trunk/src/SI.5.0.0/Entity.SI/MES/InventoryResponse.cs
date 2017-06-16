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

        public List<MES_Interface_Inventory> Inventorys { get; set; }

    }
}
