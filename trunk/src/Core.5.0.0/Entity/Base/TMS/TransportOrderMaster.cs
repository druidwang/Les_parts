using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TransportOrderMaster : EntityBase
    {
        #region O/R Mapping Properties
		
		public string OrderNo { get; set; }
		public string ExternalOrderNo { get; set; }
		public string ReferenceOrderNo { get; set; }
		public string Flow { get; set; }
		public string FlowDescription { get; set; }
		public Int16? Status { get; set; }
		public string Carrier { get; set; }
		public string CarrierName { get; set; }
		public string Vehicle { get; set; }
		public string Tonnage { get; set; }
		public string DrivingNo { get; set; }
		public string Driver { get; set; }
		public  DriverMobilePhone { get; set; }
		public Decimal? LoadVolume { get; set; }
		public Decimal? LoadWeight { get; set; }
		public Decimal? MinLoadRate { get; set; }
		public Boolean? IsAutoSubmit { get; set; }
		public Boolean? IsAutoStart { get; set; }
		public string ShipFrom { get; set; }
		public string ShipFromAddress { get; set; }
		public string ShipTo { get; set; }
		public string ShipToAddress { get; set; }
		public Int16 TransportMode { get; set; }
		public string PriceList { get; set; }
		public string BillAddress { get; set; }
		public DateTime CreateDate { get; set; }
		public string CreateUserId { get; set; }
		public string CreateUserName { get; set; }
		public DateTime LastModifyDate { get; set; }
		public string LastModifyUserId { get; set; }
		public string LastModifyUserName { get; set; }
		public DateTime? SubmitDate { get; set; }
		public string SubmitUser { get; set; }
		public string SubmitUserName { get; set; }
		public DateTime? StartDate { get; set; }
		public string StartUser { get; set; }
		public string StartUserName { get; set; }
		public DateTime? CloseDate { get; set; }
		public string CloseUserName { get; set; }
		public string CloseUser { get; set; }
		public DateTime? CancelDate { get; set; }
		public string CancelUser { get; set; }
		public string CancelUserName { get; set; }
		public Int32? Version { get; set; }
        
        #endregion

		public override int GetHashCode()
        {
			if (OrderNo != null)
            {
                return OrderNo.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            TransportOrderMaster another = obj as TransportOrderMaster;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.OrderNo == another.OrderNo);
            }
        } 
    }
	
}
