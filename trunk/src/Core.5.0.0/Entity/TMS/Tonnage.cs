using System;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{

    public partial class Tonnage 
    {
        #region Non O/R Mapping Properties

        //TODO: Add Non O/R Mapping Properties here. 
        public string Name
        {
            get
            {
                return this.Volume.ToString("0.########");
            }
        }
        #endregion
    }
}