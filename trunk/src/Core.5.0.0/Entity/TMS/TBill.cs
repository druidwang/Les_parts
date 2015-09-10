using System;
using System.Collections.Generic;
using System.Linq;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
  
    public partial class TBill 
    {
        #region Non O/R Mapping Properties

        public IList<TBillDet> TBillDets { get; set; }

        public string CarrierName
        {
            get
            {
                return this.Carrier + "[" + this.CarrierDesc + "]";
            }
        }

        #endregion
    }
}