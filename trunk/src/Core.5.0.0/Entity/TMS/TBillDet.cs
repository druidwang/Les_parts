using System;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    
    public partial class TBillDet 
    {
        #region Non O/R Mapping Properties
        public int Count { get; set; }
        public decimal Qty { get; set; }
        public decimal ActVolume { get; set; }
        public string Status { get; set; }
        private string _waybillNo;
        public string WaybillNo
        {
            get
            {
                if (this.Waybill != null)
                {
                    return this.Waybill.WaybillNo;
                }
                else
                {
                    return _waybillNo;
                }
            }
            set
            {
                _waybillNo = value;
            }
        }

        private string _shipTo;
        public string ShipTo
        {
            get
            {
                if (this.Waybill != null)
                {
                    return this.Waybill.ShipTo;
                }
                else
                {
                    return _shipTo;
                }
            }
            set
            {
                _shipTo = value;
            }
        }
        private string _shipFrom;
        public string ShipFrom
        {
            get
            {
                if (this.Waybill != null)
                {
                    return this.Waybill.ShipFrom;
                }
                else
                {
                    return _shipFrom;
                }
            }
            set
            {
                _shipFrom = value;
            }
        }
        private string _shipToDesc;
        public string ShipToDesc
        {
            get
            {
                if (this.Waybill != null)
                {
                    return this.Waybill.ShipToDesc;
                }
                else
                {
                    return _shipToDesc;
                }
            }
            set
            {
                _shipToDesc = value;
            }
        }
        private string _shipFromDesc;
        public string ShipFromDesc
        {
            get
            {
                if (this.Waybill != null)
                {
                    return this.Waybill.ShipFromDesc;
                }
                else
                {
                    return _shipFromDesc;
                }
            }
            set
            {
                _shipFromDesc = value;
            }
        }
        private string _shipToName;
        public string ShipToName
        {
            get
            {
                if (this.Waybill != null)
                {
                    return this.Waybill.ShipToName;
                }
                else
                {
                    return _shipToName;
                }
            }
            set
            {
                _shipToName = value;
            }
        }
        private string _shipFromName;
        public string ShipFromName
        {

            get
            {
                if (this.Waybill != null)
                {
                    return this.Waybill.ShipFromName;
                }
                else
                {
                    return _shipFromName;
                }
            }
            set
            {
                _shipFromName = value;
            }
        }
        public string FlowName
        {
            get
            {
                if (String.IsNullOrEmpty(this.Flow)) return string.Empty;
                return this.Flow + "[" + this.FlowDesc + "]";
            }
        }

        #endregion
    }
}