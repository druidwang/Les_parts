using System;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{

    public partial class PlaceDet
    {
        #region Non O/R Mapping Properties

        private Boolean _isBlankDetail = false;
        /// <summary>
        /// 辅助字段，判断该Detail是否新加的空行
        /// </summary>
        public Boolean IsBlankDetail
        {
            get
            {
                return _isBlankDetail;
            }
            set
            {
                _isBlankDetail = value;
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