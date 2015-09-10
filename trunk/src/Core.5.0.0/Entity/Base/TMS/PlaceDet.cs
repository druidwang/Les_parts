using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class PlaceDet : EntityBase
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
        private Decimal _km;
        public Decimal Km
        {
            get
            {
                return _km;
            }
            set
            {
                _km = value;
            }
        }
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
		private string _recUser;
		public string RecUser
		{
			get
			{
				return _recUser;
			}
			set
			{
				_recUser = value;
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
            PlaceDet another = obj as PlaceDet;

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
