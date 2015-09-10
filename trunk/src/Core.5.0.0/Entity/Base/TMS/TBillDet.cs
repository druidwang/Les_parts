using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TBillDet : EntityBase
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
		private Waybill _waybill;
		public Waybill Waybill
		{
			get
			{
				return _waybill;
			}
			set
			{
				_waybill = value;
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
		private Decimal? _headDiscount;
		public Decimal? HeadDiscount
		{
			get
			{
				return _headDiscount;
			}
			set
			{
				_headDiscount = value;
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
        private int _actBill;
        public int ActBill
		{
			get
			{
                return _actBill;
			}
			set
			{
                _actBill = value;
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
            TBillDet another = obj as TBillDet;

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
