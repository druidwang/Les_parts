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
		
        public string Code
        {
            get;
            set;
        }

		public string Desc
		{
            get;
            set;
		}

        public Decimal Weight { get; set; }

		public Decimal Volume
		{
            get;
            set;
		}

		public string CreateUserNm
		{
            get;
            set;
		}

		public string CreateUser
		{
            get;
            set;
		}

		public DateTime CreateDate
		{
            get;
            set;
		}

		public string LastModifyUserNm
		{
            get;
            set;
		}

		public string LastModifyUser
		{
            get;
            set;
		}

		public DateTime LastModifyDate
		{
            get;
            set;
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
