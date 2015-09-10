using System;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    public partial class TransportAddress 
    {
        #region Non O/R Mapping Properties

        //TODO: Add Non O/R Mapping Properties here. 

        public string Description
        {
            get
            {
                return this.Country + this.Province + this.City + this.District + this.Street + this.Address;
            }
        }

        #endregion
    }
}