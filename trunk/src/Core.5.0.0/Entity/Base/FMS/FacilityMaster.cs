using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;

//TODO: Add other using statements here

namespace com.Sconit.Entity.FMS
{
    [Serializable]
    public partial class FacilityMaster : EntityBase
    {
        #region O/R Mapping Properties
		
		private string _fCID;
		public string FCID
		{
			get
			{
				return _fCID;
			}
			set
			{
				_fCID = value;
			}
		}
		private string _name;
		public string Name
		{
			get
			{
				return _name;
			}
			set
			{
				_name = value;
			}
		}
		private string _specification;
		public string Specification
		{
			get
			{
				return _specification;
			}
			set
			{
				_specification = value;
			}
		}
		private string _capacity;
		public string Capacity
		{
			get
			{
				return _capacity;
			}
			set
			{
				_capacity = value;
			}
		}
		private DateTime? _manufactureDate;
		public DateTime? ManufactureDate
		{
			get
			{
				return _manufactureDate;
			}
			set
			{
				_manufactureDate = value;
			}
		}
		private string _manufacturer;
		public string Manufacturer
		{
			get
			{
				return _manufacturer;
			}
			set
			{
				_manufacturer = value;
			}
		}
		private string _serialNo;
		public string SerialNo
		{
			get
			{
				return _serialNo;
			}
			set
			{
				_serialNo = value;
			}
		}
		private string _assetNo;
		public string AssetNo
		{
			get
			{
				return _assetNo;
			}
			set
			{
				_assetNo = value;
			}
		}
		private string _warrantyInfo;
		public string WarrantyInfo
		{
			get
			{
				return _warrantyInfo;
			}
			set
			{
				_warrantyInfo = value;
			}
		}
		private string _techInfo;
		public string TechInfo
		{
			get
			{
				return _techInfo;
			}
			set
			{
				_techInfo = value;
			}
		}
		private string _supplier;
		public string Supplier
		{
			get
			{
				return _supplier;
			}
			set
			{
				_supplier = value;
			}
		}
		private string _supplierInfo;
		public string SupplierInfo
		{
			get
			{
				return _supplierInfo;
			}
			set
			{
				_supplierInfo = value;
			}
		}
		private string _pONo;
		public string PONo
		{
			get
			{
				return _pONo;
			}
			set
			{
				_pONo = value;
			}
		}
        private string _effDate;
        public string EffDate
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
		private string _price;
		public string Price
		{
			get
			{
				return _price;
			}
			set
			{
				_price = value;
			}
		}
		private string _owner;
		public string Owner
		{
			get
			{
				return _owner;
			}
			set
			{
				_owner = value;
			}
		}
        private string _ownerDescription;
		public string OwnerDescription
		{
			get
			{
                return _ownerDescription;
			}
			set
			{
                _ownerDescription = value;
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

        private bool _isInStore;
        public Boolean IsInStore
		{
			get
			{
                return _isInStore;
			}
			set
			{
                _isInStore = value;
			}
		}
		private string _oldChargePerson;
		public string OldChargePerson
		{
			get
			{
				return _oldChargePerson;
			}
			set
			{
				_oldChargePerson = value;
			}
		}
		private string _currChargePerson;
		public string CurrChargePerson
		{
			get
			{
				return _currChargePerson;
			}
			set
			{
				_currChargePerson = value;
			}
		}
		private string _chargeSite;
		public string ChargeSite
		{
			get
			{
				return _chargeSite;
			}
			set
			{
				_chargeSite = value;
			}
		}
        private string _chargeOrganization;
        public string ChargeOrganization
		{
			get
			{
                return _chargeOrganization;
			}
			set
			{
                _chargeOrganization = value;
			}
		}
		private DateTime? _chargeDate;
        public DateTime? ChargeDate
		{
			get
			{
				return _chargeDate;
			}
			set
			{
				_chargeDate = value;
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
		private string _maintainType;
		public string MaintainType
		{
			get
			{
				return _maintainType;
			}
			set
			{
				_maintainType = value;
			}
		}
        private DateTime? _maintainStartDate;
        public DateTime? MaintainStartDate
		{
			get
			{
                return _maintainStartDate;
			}
			set
			{
                _maintainStartDate = value;
			}
		}

        private Int32? _maintainPeriod;
        public Int32? MaintainPeriod
        {
            get
            {
                return _maintainPeriod;
            }
            set
            {
                _maintainPeriod = value;
            }
        }

        private Int32? _maintainLeadTime;
        public Int32? MaintainLeadTime
        {
            get
            {
                return _maintainLeadTime;
            }
            set
            {
                _maintainLeadTime = value;
            }
        }

        private DateTime? _nextMaintainTime;
        public DateTime? NextMaintainTime
        {
            get
            {
                return _nextMaintainTime;
            }
            set
            {
                _nextMaintainTime = value;
            }
        }

        private Int32? _maintainTypePeriod;
        public Int32? MaintainTypePeriod
        {
            get
            {
                return _maintainTypePeriod;
            }
            set
            {
                _maintainTypePeriod = value;
            }
        }


        private string _oldChargePersonName;
        public string OldChargePersonName
        {
            get
            {
                return _oldChargePersonName;
            }
            set
            {
                _oldChargePersonName = value;
            }
        }

        private string _currChargePersonName;
        public string CurrChargePersonName
        {
            get
            {
                return _currChargePersonName;
            }
            set
            {
                _currChargePersonName = value;
            }
        }

        private Boolean _isOffBalance;
        public Boolean IsOffBalance
        {
            get
            {
                return _isOffBalance;
            }
            set
            {
                _isOffBalance = value;
            }
        }

        private Boolean _isAsset;
        public Boolean IsAsset
        {
            get
            {
                return _isAsset;
            }
            set
            {
                _isAsset = value;
            }
        }

        public string _refenceCode;
        public string RefenceCode
        {
            get
            {
                return _refenceCode;
            }
            set
            {
                _refenceCode = value;
            }
        }

        public string _maintainGroup;
        public string MaintainGroup
        {
            get
            {
                return _maintainGroup;
            }
            set
            {
                _maintainGroup = value;
            }
        }
        private string _printTemplate;
        public string PrintTemplate
        {
            get
            {
                return _printTemplate;
            }
            set
            {
                _printTemplate = value;
            }
        }
        #endregion

		public override int GetHashCode()
        {
			if (FCID != null)
            {
                return FCID.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            FacilityMaster another = obj as FacilityMaster;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.FCID == another.FCID);
            }
        } 
    }
	
}
