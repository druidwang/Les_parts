using System;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
 
    public partial class Mileage
    {
        #region Non O/R Mapping Properties

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