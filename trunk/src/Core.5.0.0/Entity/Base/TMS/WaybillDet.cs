using com.Sconit.Entity;
using System;
using System.Collections;
using System.Collections.Generic;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class WaybillDet : EntityBase
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
        private Int32 _seq;
        public Int32 Seq
        {
            get
            {
                return _seq;
            }
            set
            {
                _seq = value;
            }
        }
        private string _dock;
        public string Dock
        {
            get
            {
                return _dock;
            }
            set
            {
                _dock = value;
            }
        }
        
        private string _remark;
        public string Remark
        {
            get
            {
                return _remark;
            }
            set
            {
                _remark = value;
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
		private string _ipNo;
		public string IpNo
		{
			get
			{
				return _ipNo;
			}
			set
			{
				_ipNo = value;
			}
		}
		private Decimal _palletQty;
		public Decimal PalletQty
		{
			get
			{
				return _palletQty;
			}
			set
			{
				_palletQty = value;
			}
		}
        public Decimal Volume { get; set; }
        public Decimal Weight { get; set; }
        public Decimal UnitPack { get; set; }
		private string _partyFromDesc;
		public string PartyFromDesc
		{
			get
			{
				return _partyFromDesc;
			}
			set
			{
				_partyFromDesc = value;
			}
		}
		private string _partyFrom;
		public string PartyFrom
		{
			get
			{
				return _partyFrom;
			}
			set
			{
				_partyFrom = value;
			}
		}
		private string _partyTo;
		public string PartyTo
		{
			get
			{
				return _partyTo;
			}
			set
			{
				_partyTo = value;
			}
		}
		private string _partyToDesc;
		public string PartyToDesc
		{
			get
			{
				return _partyToDesc;
			}
			set
			{
				_partyToDesc = value;
			}
		}
		private DateTime? _departTime;
		public DateTime? DepartTime
		{
			get
			{
				return _departTime;
			}
			set
			{
				_departTime = value;
			}
		}
		private DateTime? _arriveTime;
		public DateTime? ArriveTime
		{
			get
			{
				return _arriveTime;
			}
			set
			{
				_arriveTime = value;
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
		private string _status;
		public string Status
		{
			get
			{
				return _status;
			}
			set
			{
				_status = value;
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
            WaybillDet another = obj as WaybillDet;

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
