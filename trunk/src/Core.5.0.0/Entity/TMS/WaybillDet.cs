using System;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    public partial class WaybillDet 
    {
        #region Non O/R Mapping Properties

        private Boolean _isBlankDetail = false;
        /// <summary>
        /// �����ֶΣ��жϸ�Detail�Ƿ��¼ӵĿ���
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

        #endregion
    }
}