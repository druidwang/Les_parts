using System;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{

    public partial class Driver
    {
        #region Non O/R Mapping Properties

        //TODO: Add Non O/R Mapping Properties here. 
        public string Desc
        {
            get
            {
                return this.Name + this.IdentityCard;
            }
        }
        #endregion
    }
}