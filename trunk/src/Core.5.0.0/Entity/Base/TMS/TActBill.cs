using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TActBill : EntityBase
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
        private bool _isBilled;
        public bool IsBilled
        {
            get
            {
                return _isBilled;
            }
            set
            {
                _isBilled = value;
            }
        }

        private string _flowCurrency;
        public string FlowCurrency
        {
            get
            {
                return _flowCurrency;
            }
            set
            {
                _flowCurrency = value;
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

        public Waybill Waybill { get; set; }
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
        private Decimal? _billAmount;
        public Decimal? BillAmount
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
        private Decimal? _billedAmount;
        public Decimal? BilledAmount
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
        private string _priceList;
        public string PriceList
        {
            get
            {
                return _priceList;
            }
            set
            {
                _priceList = value;
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
        private Boolean _isIncludeTax;
        public Boolean IsIncludeTax
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
        private Boolean _isProvEst;
        public Boolean IsProvEst
        {
            get
            {
                return _isProvEst;
            }
            set
            {
                _isProvEst = value;
            }
        }

        private DateTime _effDate;
        public DateTime EffDate
        {
            get
            {
                return _effDate;
            }
            set
            {
                _effDate = value;
            }
        }
        private string _pricingMethod;
        public string PricingMethod
        {
            get
            {
                return _pricingMethod;
            }
            set
            {
                _pricingMethod = value;
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
        private Decimal? _unitPrice;
        public Decimal? UnitPrice
        {
            get
            {
                return _unitPrice;
            }
            set
            {
                _unitPrice = value;
            }
        }
		public int RoundUpOpt { get; set; }
        public decimal BilledQty { get; set; }
        public decimal BillQty { get; set; }
        
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
            TActBill another = obj as TActBill;

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
