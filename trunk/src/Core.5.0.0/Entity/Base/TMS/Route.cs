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
		
		private Int32 _id;
		public Int32 Id
		{
			get
			{
				return _id;
			}
			set
			{
				_id = value;
			}
		}
		private string _routeNo;
		public string RouteNo
		{
			get
			{
				return _routeNo;
			}
			set
			{
				_routeNo = value;
			}
		}
		private string _frontWaybillNo;
		public string FrontWaybillNo
		{
			get
			{
				return _frontWaybillNo;
			}
			set
			{
				_frontWaybillNo = value;
			}
		}
		private string _waybillNo;
		public string WaybillNo
		{
			get
			{
				return _waybillNo;
			}
			set
			{
				_waybillNo = value;
			}
		}
		private string _type;
		public string Type
		{
			get
			{
				return _type;
			}
			set
			{
				_type = value;
			}
		}
		private string _shipFrom;
		public string ShipFrom
		{
			get
			{
				return _shipFrom;
			}
			set
			{
				_shipFrom = value;
			}
		}
		private string _shipTo;
		public string ShipTo
		{
			get
			{
				return _shipTo;
			}
			set
			{
				_shipTo = value;
			}
		}
		private string _carrier;
		public string Carrier
		{
			get
			{
				return _carrier;
			}
			set
			{
				_carrier = value;
			}
		}
		private string _shipFromDesc;
		public string ShipFromDesc
		{
			get
			{
				return _shipFromDesc;
			}
			set
			{
				_shipFromDesc = value;
			}
		}
		private string _shipToDesc;
		public string ShipToDesc
		{
			get
			{
				return _shipToDesc;
			}
			set
			{
				_shipToDesc = value;
			}
		}
		private string _carrierDesc;
		public string CarrierDesc
		{
			get
			{
				return _carrierDesc;
			}
			set
			{
				_carrierDesc = value;
			}
		}
		private string _flowDesc;
		public string FlowDesc
		{
			get
			{
				return _flowDesc;
			}
			set
			{
				_flowDesc = value;
			}
		}
		private string _flow;
		public string Flow
		{
			get
			{
				return _flow;
			}
			set
			{
				_flow = value;
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
