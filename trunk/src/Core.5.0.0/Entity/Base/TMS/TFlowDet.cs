using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TFlowDet : EntityBase
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
        private string _category;
        public string Category
        {
            get
            {
                return _category;
            }
            set
            {
                _category = value;
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
        public int RoundUpOpt { get; set; }
        public string Currency { get; set; }
        public string CarrierDesc { get; set; }
        public string Tonnage { get; set; }
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
            TFlowDet another = obj as TFlowDet;

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
