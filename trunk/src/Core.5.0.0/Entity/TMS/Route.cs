using System;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
  
    public partial class Route 
    {
        #region Non O/R Mapping Properties

        public string CarrierName
        {
            get
            {
                return this.Carrier + "[" + this.CarrierDesc + "]";
            }
        }

        public string FlowName
        {
            get
            {
                if (String.IsNullOrEmpty(this.Flow)) return string.Empty;
                return this.Flow + "[" + this.FlowDesc + "]";
            }
        }

        public string ShipFromTo
        {
            get
            {
                return this.ShipFrom + "-" + this.ShipTo;
            }
        }

        public string ShipToName
        {
            get
            {
                return this.ShipTo + "[" + this.ShipToDesc + "]";
            }
        }

        public string ShipFromName
        {
            get
            {
                return this.ShipFrom + "[" + this.ShipFromDesc + "]";
            }
        }

        #endregion
    }
}