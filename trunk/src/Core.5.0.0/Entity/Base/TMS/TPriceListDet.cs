using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TPriceListDet : EntityBase
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
        private DateTime _startDate;
        public DateTime StartDate
        {
            get
            {
                return _startDate;
            }
            set
            {
                _startDate = value;
            }
        }
        private DateTime? _endDate;
        public DateTime? EndDate
        {
            get
            {
                return _endDate;
            }
            set
            {
                _endDate = value;
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
        private Decimal _unitPrice;
        public Decimal UnitPrice
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

        private string _tonnage;
        public string Tonnage
        {
            get
            {
                return _tonnage;
            }
            set
            {
                _tonnage = value;
            }
        }
        public string Category { get; set; }
        public Decimal? MaxPrice { get; set; }
        private Decimal? _minPrice;
        public Decimal? MinPrice
        {
            get
            {
                return _minPrice;
            }
            set
            {
                _minPrice = value;
            }
        }
        private Decimal? _sendFee;
        public Decimal? SendFee
        {
            get
            {
                return _sendFee;
            }
            set
            {
                _sendFee = value;
            }
        }
        private Decimal? _inOutFee;
        public Decimal? InOutFee
        {
            get
            {
                return _inOutFee;
            }
            set
            {
                _inOutFee = value;
            }
        }
        private Decimal? _serviceFee;
        public Decimal? ServiceFee
        {
            get
            {
                return _serviceFee;
            }
            set
            {
                _serviceFee = value;
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
        /*
         private Decimal? _minLotSize;
         public Decimal? MinLotSize
         {
             get
             {
                 return _minLotSize;
             }
             set
             {
                 _minLotSize = value;
             }
         }
         private Decimal? _monthlyQty;
         public Decimal? MonthlyQty
         {
             get
             {
                 return _monthlyQty;
             }
             set
             {
                 _monthlyQty = value;
             }
         }
         private Decimal? _monthlyPrice;
         public Decimal? MonthlyPrice
         {
             get
             {
                 return _monthlyPrice;
             }
             set
             {
                 _monthlyPrice = value;
             }
         }
         * */
        private Decimal? _startQty;
        public Decimal? StartQty
        {
            get
            {
                return _startQty;
            }
            set
            {
                _startQty = value;
            }
        }
        private Decimal? _endQty;
        public Decimal? EndQty
        {
            get
            {
                return _endQty;
            }
            set
            {
                _endQty = value;
            }
        }
        public string ShipFrom { get; set; }
        public string ShipTo { get; set; }
        public string ShipFromDesc { get; set; }
        public string ShipToDesc { get; set; }
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
            TPriceListDet another = obj as TPriceListDet;

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
