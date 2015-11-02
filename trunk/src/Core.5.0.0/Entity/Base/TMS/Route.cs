using com.Sconit.Entity;
using System;
using System.Collections;
using System.Collections.Generic;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class Route : EntityBase
    {
        #region O/R Mapping Properties

        public Int32 Id
        {
            get;
            set;
        }

		public string RouteNo
		{
            get;
            set;
		}

		public string FrontWaybillNo
		{
            get;
            set;
		}

		public string WaybillNo
		{
            get;
            set;
		}

		public string Type
		{
            get;
            set;
		}

		public string ShipFrom
		{
            get;
            set;
		}

		public string ShipTo
		{
            get;
            set;
		}

		public string Carrier
		{
            get;
            set;
		}
	
		public string ShipFromDesc
		{
            get;
            set;
		}

		public string ShipToDesc
		{
            get;
            set;
		}

		public string CarrierDesc
		{
            get;
            set;
		}

		public string FlowDesc
		{
            get;
            set;
		}

		public string Flow
		{
            get;
            set;
		}

		public DateTime CreateDate
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
        
        #endregion

		public override int GetHashCode()
        {
			if (Id != null)
            {
                return Id.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            Route another = obj as Route;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.Id == another.Id);
            }
        } 
    }
	
}
