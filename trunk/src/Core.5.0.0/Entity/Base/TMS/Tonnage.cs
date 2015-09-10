using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class Tonnage : EntityBase
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
        public Decimal Weight { get; set; }

		private Decimal _volume;
		public Decimal Volume
		{
			get
			{
				return _volume;
			}
			set
			{
				_volume = value;
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
            Tonnage another = obj as Tonnage;

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
