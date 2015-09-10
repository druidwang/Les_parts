using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class Freight : EntityBase
    {
        #region O/R Mapping Properties
		
		private string _freightNo;
		public string FreightNo
		{
			get
			{
				return _freightNo;
			}
			set
			{
				_freightNo = value;
			}
		}
        private string _billAddr;
        public string BillAddr
        {
            get
            {
                return _billAddr;
            }
            set
            {
                _billAddr = value;
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
		private string _reason;
		public string Reason
		{
			get
			{
				return _reason;
			}
			set
			{
				_reason = value;
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
		private Decimal _freightNumber;
		public Decimal FreightNumber
		{
			get
			{
                return _freightNumber;
			}
			set
			{
                _freightNumber = value;
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
		private DateTime? _cancelDate;
		public DateTime? CancelDate
		{
			get
			{
				return _cancelDate;
			}
			set
			{
				_cancelDate = value;
			}
		}
		private string _cancelUserNm;
		public string CancelUserNm
		{
			get
			{
				return _cancelUserNm;
			}
			set
			{
				_cancelUserNm = value;
			}
		}
		private string _cancelUser;
		public string CancelUser
		{
			get
			{
				return _cancelUser;
			}
			set
			{
				_cancelUser = value;
			}
		}
        public DateTime? SubmitDate { get; set; }
        public string SubmitUser { get; set; }
        public string SubmitUserNm { get; set; }
        public DateTime? CloseDate { get; set; }
        public string CloseUser { get; set; }
        public string CloseUserNm { get; set; }

        public string Currency { get; set; }
        public string ShipFromDesc { get; set; }
        public string ShipToDesc { get; set; }
        public string CarrierDesc { get; set; }
        public string Comment { get; set; }

        private Int32 _version;
        public Int32 Version
        {
            get
            {
                return _version;
            }
            set
            {
                _version = value;
            }
        }
        #endregion

		public override int GetHashCode()
        {
			if (FreightNo != null)
            {
                return FreightNo.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            Freight another = obj as Freight;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.FreightNo == another.FreightNo);
            }
        } 
    }
	
}
