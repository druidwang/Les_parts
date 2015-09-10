using System;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
  
    public partial class TPriceListDet
    {
        #region Non O/R Mapping Properties

        /// <summary>
        /// 提送费+其他服务费+装卸货费
        /// </summary>
        public decimal Fee
        {
            get
            {
                return (this.InOutFee.HasValue ? this.InOutFee.Value : 0)
                            + (this.SendFee.HasValue ? this.SendFee.Value : 0)
                            + (this.ServiceFee.HasValue ? this.ServiceFee.Value : 0);
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