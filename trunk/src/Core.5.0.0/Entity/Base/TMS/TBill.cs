using com.Sconit.Entity;
using System;
using System.Collections;
using System.Collections.Generic;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TBill : EntityBase
    {
        #region O/R Mapping Properties
		
		private string _billNo;
		public string BillNo
		{
			get
			{
				return _billNo;
			}
			set
			{
				_billNo = value;
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
		private string _extBillNo;
		public string ExtBillNo
		{
			get
			{
				return _extBillNo;
			}
			set
			{
				_extBillNo = value;
			}
		}
		private Boolean? _isIncludeTax;
		public Boolean? IsIncludeTax
		{
			get
			{
				return _isIncludeTax;
			}
			set
			{
				_isIncludeTax = value;
			}
		}
		private string _taxCode;
		public string TaxCode
		{
			get
			{
				return _taxCode;
			}
			set
			{
				_taxCode = value;
			}
		}
		private string _refBillNo;
		public string RefBillNo
		{
			get
			{
				return _refBillNo;
			}
			set
			{
				_refBillNo = value;
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
		private string _currency;
		public string Currency
		{
			get
			{
				return _currency;
			}
			set
			{
				_currency = value;
			}
		}
		private Decimal? _discount;
		public Decimal? Discount
		{
			get
			{
				return _discount;
			}
			set
			{
				_discount = value;
			}
		}
        private Decimal _billAmount;
        public Decimal BillAmount
        {
            get
            {
                return _billAmount;
            }
            set
            {
                _billAmount = value;
            }
        }
        private Decimal _billedAmount;
        public Decimal BilledAmount
        {
            get
            {
                return _billedAmount;
            }
            set
            {
                _billedAmount = value;
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
        private DateTime? _submitDate;
        public DateTime? SubmitDate
        {
            get
            {
                return _submitDate;
            }
            set
            {
                _submitDate = value;
            }
        }
        private string _submitUser;
        public string SubmitUser
        {
            get
            {
                return _submitUser;
            }
            set
            {
                _submitUser = value;
            }
        }
        private string _submitUserNm;
        public string SubmitUserNm
        {
            get
            {
                return _submitUserNm;
            }
            set
            {
                _submitUserNm = value;
            }
        }
        private string _closeUserNm;
        public string CloseUserNm
        {
            get
            {
                return _closeUserNm;
            }
            set
            {
                _closeUserNm = value;
            }
        }
        private DateTime? _closeDate;
        public DateTime? CloseDate
        {
            get
            {
                return _closeDate;
            }
            set
            {
                _closeDate = value;
            }
        }
        private string _closeUser;
        public string CloseUser
        {
            get
            {
                return _closeUser;
            }
            set
            {
                _closeUser = value;
            }
        }

        private DateTime? _voidDate;
        public DateTime? VoidDate
        {
            get
            {
                return _voidDate;
            }
            set
            {
                _voidDate = value;
            }
        }
        private string _voidUserNm;
        public string VoidUserNm
        {
            get
            {
                return _voidUserNm;
            }
            set
            {
                _voidUserNm = value;
            }
        }
        private string _voidUser;
        public string VoidUser
        {
            get
            {
                return _voidUser;
            }
            set
            {
                _voidUser = value;
            }
        }
        #endregion

		public override int GetHashCode()
        {
			if (BillNo != null)
            {
                return BillNo.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            TBill another = obj as TBill;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.BillNo == another.BillNo);
            }
        } 
    }
	
}
