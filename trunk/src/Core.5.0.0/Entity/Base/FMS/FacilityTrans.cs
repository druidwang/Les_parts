using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;

//TODO: Add other using statements here

namespace com.Sconit.Entity.FMS
{
    [Serializable]
    public partial class FacilityTrans : EntityBase
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
        private CodeMaster.FacilityTransType _transType;
        public CodeMaster.FacilityTransType TransType
        {
            get
            {
                return _transType;
            }
            set
            {
                _transType = value;
            }
        }
        private string _fromChargePerson;
        public string FromChargePerson
        {
            get
            {
                return _fromChargePerson;
            }
            set
            {
                _fromChargePerson = value;
            }
        }
        private string _toChargePerson;
        public string ToChargePerson
        {
            get
            {
                return _toChargePerson;
            }
            set
            {
                _toChargePerson = value;
            }
        }
        private string _fromOrganization;
        public string FromOrganization
        {
            get
            {
                return _fromOrganization;
            }
            set
            {
                _fromOrganization = value;
            }
        }
        private string _toOrganization;
        public string ToOrganization
        {
            get
            {
                return _toOrganization;
            }
            set
            {
                _toOrganization = value;
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
        private DateTime? _effDate;
        public DateTime? EffDate
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
        private string _attachment;
        public string Attachment
        {
            get
            {
                return _attachment;
            }
            set
            {
                _attachment = value;
            }
        }
        private string _facilityCategory;
        public string FacilityCategory
        {
            get
            {
                return _facilityCategory;
            }
            set
            {
                _facilityCategory = value;
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

        private string _fromChargeSite;
        public string FromChargeSite
        {
            get
            {
                return _fromChargeSite;
            }
            set
            {
                _fromChargeSite = value;
            }
        }
        private string _toChargeSite;
        public string ToChargeSite
        {
            get
            {
                return _toChargeSite;
            }
            set
            {
                _toChargeSite = value;
            }
        }

        private string _fromChargePersonName;
        public string FromChargePersonName
        {
            get
            {
                return _fromChargePersonName;
            }
            set
            {
                _fromChargePersonName = value;
            }
        }
        private string _toChargePersonName;
        public string ToChargePersonName
        {
            get
            {
                return _toChargePersonName;
            }
            set
            {
                _toChargePersonName = value;
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
        private string _facilityName;
        public string FacilityName
        {
            get
            {
                return _facilityName;
            }
            set
            {
                _facilityName = value;
            }
        }

        private string _batchNo;
        public string BatchNo
        {
            get
            {
                return _batchNo;
            }
            set
            {
                _batchNo = value;
            }
        }
        #endregion

        public override int GetHashCode()
        {
            if (Id != 0)
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
            FacilityTrans another = obj as FacilityTrans;

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
