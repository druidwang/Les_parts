using System;
using System.Collections.Generic;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    public partial class TransportOrderMaster
    {
        #region Non O/R Mapping Properties

        public IList<TransportOrderRoute> TransportOrderRouteList { get; set; }
        public IList<TransportOrderDetail> TransportOrderDetailList { get; set; }

        #endregion
    }
}