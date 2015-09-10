using System;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    public partial  class WaybillItem
    {
        #region Non O/R Mapping Properties

        public int Id { get; set; }

        public string IpNo { get; set; }
        public string Item { get; set; }
        public string Desc1 { get; set; }
        public string UOM { get; set; }
        //public decimal UC { get; set; }
        public decimal Qty { get; set; }
        public decimal RecQty { get; set; }

        public decimal Volume { get; set; }

        #endregion
    }
}