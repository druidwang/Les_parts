using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class Freight : EntityBase
    {
        #region O/R Mapping Properties
		
		public string FreightNo
		{
            get;
            set;
		}

        public string BillAddr
        {
            get;
            set;
        }

		public string Carrier
		{
            get;
            set;
		}

		public string WaybillNo
		{
            get;
            set;
		}

		public string ShipFrom
		{
            get;
            set;
		}

		public string ShipTo
		{
            get;
            set;
		}

		public string Reason
		{
            get;
            set;
		}

		public string Remark
		{
            get;
            set;
		}

		public Decimal FreightNumber
		{
            get;
            set;
		}

		public string Status
		{
            get;
            set;
		}

		public DateTime CreateDate
		{
            get;
            set;
		}

		public string CreateUserNm
		{
            get;
            set;
		}

		public string CreateUser
		{
            get;
            set;
		}

		public DateTime LastModifyDate
		{
            get;
            set;
		}

		public string LastModifyUser
		{
            get;
            set;
		}

		public string LastModifyUserNm
		{
            get;
            set;
		}

		public DateTime? CancelDate
		{
            get;
            set;
		}

		public string CancelUserNm
		{
            get;
            set;
		}

		public string CancelUser
		{
            get;
            set;
		}
        public DateTime? SubmitDate { get; set; }
        public string SubmitUser { get; set; }
        public string SubmitUserNm { get; set; }
        public DateTime? CloseDate { get; set; }
        public string CloseUser { get; set; }
        public string CloseUserNm { get; set; }

        public string Currency { get; set; }
        public string ShipFromDesc { get; set; }
        public string ShipToDesc { get; set; }
        public string CarrierDesc { get; set; }
        public string Comment { get; set; }

        public Int32 Version
        {
            get;
            set;
        }
        #endregion

		public override int GetHashCode()
        {
			if (FreightNo != null)
            {
                return FreightNo.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            Freight another = obj as Freight;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.FreightNo == another.FreightNo);
            }
        } 
    }
	
}
