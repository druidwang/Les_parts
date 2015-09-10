using System;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
   
    public partial class TActBill
    {
        #region Non O/R Mapping Properties

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
        private string _carrierName;
        public string CarrierName
        {
            get
            {
                if (this.Waybill != null)
                {
                    return this.Waybill.CarrierName;
                }
                else
                {
                    return _carrierName;
                }
            }
            set
            {
                _carrierName = value;
            }
        }

        private string _flowName;
        public string FlowName
        {
            get
            {
                if (this.Waybill != null)
                {
                    return this.Waybill.FlowName;
                }
                else
                {
                    return _flowName;
                }
            }
            set
            {
                _flowName = value;
            }
        }

        public DateTime? StartDate { get; set; }
        public decimal? ActVolume { get; set; }
        public decimal? Km { get; set; }
        public string Vehicle { get; set; }
        public string Driver { get; set; }
        public string Carrier { get; set; }
        public string Tonnage { get; set; }
        #endregion
    }
}