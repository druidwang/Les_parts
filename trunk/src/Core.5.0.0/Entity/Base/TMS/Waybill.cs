using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class Waybill : EntityBase
    {
        #region O/R Mapping Properties

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
        public string Phone { get; set; }
        public string SubType { get; set; }
        public bool IsMorePlace { get; set; }
        public Decimal? Km { get; set; }
        public string MorePlace { get; set; }
        public Boolean IsAutoStart { get; set; }
        public Boolean IsAutoRelease { get; set; }
        public Boolean IsASN { get; set; }
        public Decimal? StartDutyCycle { get; set; }
        public Int32? FlowDet { get; set; }

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
        private Decimal? _freight;
        public Decimal? Freight
        {
            get
            {
                return _freight;
            }
            set
            {
                _freight = value;
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
        private Decimal _actPalletQty;
        public Decimal ActPalletQty
        {
            get
            {
                return _actPalletQty;
            }
            set
            {
                _actPalletQty = value;
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
        private Decimal? _palletVolume;
        public Decimal? PalletVolume
        {
            get
            {
                return _palletVolume;
            }
            set
            {
                _palletVolume = value;
            }
        }
        public Decimal Weight { get; set; }
        public Decimal ActWeight { get; set; }
        public Decimal ActVolume { get; set; }
        public Decimal? ActVolume2 { get; set; }
        public Decimal ActUnitPack { get; set; }
        public Decimal UnitPack { get; set; }
        private Decimal _volume;
        /// <summary>
        /// 物料体积
        /// </summary>
        public Decimal Volume
        {
            get
            {
                return _volume;
            }
            set
            {
                _volume = value;
            }
        }
        /// <summary>
        /// 车辆载重
        /// </summary>
        public Decimal? TonnageWeight { get; set; }
        
        /// <summary>
        /// 车辆体积
        /// </summary>
        public Decimal? TonnageVolume { get; set; }
        private string _refNo;
        public string RefNo
        {
            get
            {
                return _refNo;
            }
            set
            {
                _refNo = value;
            }
        }

        private string _extNo;
        public string ExtNo
        {
            get
            {
                return _extNo;
            }
            set
            {
                _extNo = value;
            }
        }
        private DateTime? _startTime;
        public DateTime? StartTime
        {
            get
            {
                return _startTime;
            }
            set
            {
                _startTime = value;
            }
        }
        private DateTime _winTime;
        public DateTime WinTime
        {
            get
            {
                return _winTime;
            }
            set
            {
                _winTime = value;
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
        private string _vehicle;
        public string Vehicle
        {
            get
            {
                return _vehicle;
            }
            set
            {
                _vehicle = value;
            }
        }
        private string _driverDesc;
        public string DriverDesc
        {
            get
            {
                return _driverDesc;
            }
            set
            {
                _driverDesc = value;
            }
        }
        private string _driver;
        public string Driver
        {
            get
            {
                return _driver;
            }
            set
            {
                _driver = value;
            }
        }
        private DateTime? _settleTime;
        public DateTime? SettleTime
        {
            get
            {
                return _settleTime;
            }
            set
            {
                _settleTime = value;
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
        private DateTime? _startDate;
        public DateTime? StartDate
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
        private string _startUserNm;
        public string StartUserNm
        {
            get
            {
                return _startUserNm;
            }
            set
            {
                _startUserNm = value;
            }
        }
        private string _startUser;
        public string StartUser
        {
            get
            {
                return _startUser;
            }
            set
            {
                _startUser = value;
            }
        }
        public Boolean? IsAutoComplete { get; set; }
        private DateTime? _completeDate;
        public DateTime? CompleteDate
        {
            get
            {
                return _completeDate;
            }
            set
            {
                _completeDate = value;
            }
        }
        private string _completeUser;
        public string CompleteUser
        {
            get
            {
                return _completeUser;
            }
            set
            {
                _completeUser = value;
            }
        }
        private string _completeUserNm;
        public string CompleteUserNm
        {
            get
            {
                return _completeUserNm;
            }
            set
            {
                _completeUserNm = value;
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
        private bool _isFree;
        public bool IsFree
        {
            get
            {
                return _isFree;
            }
            set
            {
                _isFree = value;
            }
        }
        private bool _authDriver;
        public bool AuthDriver
        {
            get
            {
                return _authDriver;
            }
            set
            {
                _authDriver = value;
            }
        }
        private bool _authVehicle;
        public bool AuthVehicle
        {
            get
            {
                return _authVehicle;
            }
            set
            {
                _authVehicle = value;
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
        public int RoundUpOpt { get; set; }
        #endregion

        public override int GetHashCode()
        {
            if (WaybillNo != null)
            {
                return WaybillNo.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            Waybill another = obj as Waybill;

            if (another == null)
            {
                return false;
            }
            else
            {
                return (this.WaybillNo == another.WaybillNo);
            }
        }
    }

}
