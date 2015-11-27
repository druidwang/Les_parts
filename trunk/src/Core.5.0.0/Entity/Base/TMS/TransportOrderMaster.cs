using System;
using System.ComponentModel.DataAnnotations;
using com.Sconit.CodeMaster;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TransportOrderMaster : EntityBase, IAuditable
    {
        #region O/R Mapping Properties
		
		public string OrderNo { get; set; }
		public string ExternalOrderNo { get; set; }
		public string ReferenceOrderNo { get; set; }
		public string Flow { get; set; }
		public string FlowDescription { get; set; }
        public TransportStatus Status { get; set; }
		public string Carrier { get; set; }
		public string CarrierName { get; set; }
		public string Vehicle { get; set; }
		public string Tonnage { get; set; }
		public string DrivingNo { get; set; }
		public string Driver { get; set; }
		public string DriverMobilePhone { get; set; }
		public Decimal? LoadVolume { get; set; }
		public Decimal? LoadWeight { get; set; }
		public Decimal? MinLoadRate { get; set; }
		public Boolean IsAutoRelease { get; set; }
		public Boolean IsAutoStart { get; set; }
        public Boolean MultiSitePick { get; set; }
        public string ShipFrom { get; set; }
		public string ShipFromAddress { get; set; }
		public string ShipTo { get; set; }
		public string ShipToAddress { get; set; }
		public com.Sconit.CodeMaster.TransportMode TransportMode { get; set; }
		public string PriceList { get; set; }
		public string BillAddress { get; set; }
		public DateTime CreateDate { get; set; }
        public Int32 CreateUserId { get; set; }
		public string CreateUserName { get; set; }
		public DateTime LastModifyDate { get; set; }
        public Int32 LastModifyUserId { get; set; }
		public string LastModifyUserName { get; set; }
		public DateTime? SubmitDate { get; set; }
        public Int32 SubmitUserId { get; set; }
		public string SubmitUserName { get; set; }
		public DateTime? StartDate { get; set; }
        public Int32 StartUserId { get; set; }
		public string StartUserName { get; set; }
		public DateTime? CloseDate { get; set; }
		public string CloseUserName { get; set; }
        public Int32 CloseUserId { get; set; }
		public DateTime? CancelDate { get; set; }
        public Int32 CancelUserId { get; set; }
		public string CancelUserName { get; set; }
		public Int32? Version { get; set; }
        public string LicenseNo { get; set; }
        public Int32? CurrentArriveSiteId { get; set; }
        public string CurrentArriveShipAddress { get; set; }
        public string CurrentArriveShipAddressDescription { get; set; }
        
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
