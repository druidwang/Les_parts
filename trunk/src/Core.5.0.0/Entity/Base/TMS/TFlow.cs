using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TFlow : EntityBase
    {
        #region O/R Mapping Properties

        private string _code;
        public string Code
        {
            get
            {
                return _code;
            }
            set
            {
                _code = value;
            }
        }
        private string _desc;
        public string Desc
        {
            get
            {
                return _desc;
            }
            set
            {
                _desc = value;
            }
        }
        private Boolean _isActive;
        public Boolean IsActive
        {
            get
            {
                return _isActive;
            }
            set
            {
                _isActive = value;
            }
        }
        private Boolean _isAutoRelease;
        public Boolean IsAutoRelease
        {
            get
            {
                return _isAutoRelease;
            }
            set
            {
                _isAutoRelease = value;
            }
        }
        public Boolean IsASN { get; set; }
        public Boolean IsAutoStart { get; set; }
        public Decimal? StartDutyCycle { get; set; }
        private Decimal _palletVolume;
        public Decimal PalletVolume
        {
            get
            {
                return _palletVolume;
            }
            set
            {
                _palletVolume = value;
            }
        }
        private string _createUserNm;
        public string CreateUserNm
        {
            get
            {
                return _createUserNm;
            }
            set
            {
                _createUserNm = value;
            }
        }
        private string _createUser;
        public string CreateUser
        {
            get
            {
                return _createUser;
            }
            set
            {
                _createUser = value;
            }
        }
        private DateTime _createDate;
        public DateTime CreateDate
        {
            get
            {
                return _createDate;
            }
            set
            {
                _createDate = value;
            }
        }
        private string _lastModifyUserNm;
        public string LastModifyUserNm
        {
            get
            {
                return _lastModifyUserNm;
            }
            set
            {
                _lastModifyUserNm = value;
            }
        }
        private string _lastModifyUser;
        public string LastModifyUser
        {
            get
            {
                return _lastModifyUser;
            }
            set
            {
                _lastModifyUser = value;
            }
        }
        private DateTime _lastModifyDate;
        public DateTime LastModifyDate
        {
            get
            {
                return _lastModifyDate;
            }
            set
            {
                _lastModifyDate = value;
            }
        }
        public string ShipFrom { get; set; }
        public string ShipTo { get; set; }
        public string ShipFromDesc { get; set; }
        public string ShipToDesc { get; set; }

        public bool IsMorePlace { get; set; }
        #endregion

        public override int GetHashCode()
        {
            if (Code != null)
            {
                return Code.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            TFlow another = obj as TFlow;

            if (another == null)
            {
                return false;
            }
            else
            {
                return (this.Code == another.Code);
            }
        }
    }

}
