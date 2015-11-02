using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TOrderMaster : EntityBase
    {
        #region O/R Mapping Properties
		
		public string OrderNo { get; set; }
		public string FreightNo { get; set; }
		public Decimal PalletQty { get; set; }
		public Decimal ActPalletQty { get; set; }
		public string Tonnage { get; set; }
		public Decimal? LoadRate { get; set; }
		public Decimal? PalletVolume { get; set; }
		public Decimal? TonnageVolume { get; set; }
		public Decimal ActVolume { get; set; }
		public Decimal ActUnitPack { get; set; }
		public Decimal UnitPack { get; set; }
		public Decimal Volume { get; set; }
		public string RefNo { get; set; }
		public string ExtNo { get; set; }
		public DateTime? StartTime { get; set; }
		public DateTime WinTime { get; set; }
		public string Status { get; set; }
		public string Type { get; set; }
		public string Category { get; set; }
		public string CarrierDesc { get; set; }
		public string Carrier { get; set; }
		public string BillAddr { get; set; }
		public string FlowCurrency { get; set; }
		public string Currency { get; set; }
		public string PriceList { get; set; }
		public string ShipFromDesc { get; set; }
		public string ShipFrom { get; set; }
		public string ShipToDesc { get; set; }
		public string ShipTo { get; set; }
		public Boolean AuthVehicle { get; set; }
		public string Vehicle { get; set; }
		public string DriverDesc { get; set; }
		public Boolean AuthDriver { get; set; }
		public string Driver { get; set; }
		public DateTime? SettleTime { get; set; }
		public string Remark { get; set; }
		public Boolean IsFreeCharge { get; set; }
		public Decimal? Freight { get; set; }
		public Boolean IsProvEst { get; set; }
		public string PricingMethod { get; set; }
		public Int32 RoundUpOpt { get; set; }
		public Decimal? MinPrice { get; set; }
		public Decimal? SendFee { get; set; }
		public Decimal? InOutFee { get; set; }
		public Decimal? ServiceFee { get; set; }
		public Decimal? UnitPrice { get; set; }
		public DateTime CreateDate { get; set; }
		public string CreateUserName { get; set; }
		public string CreateUserId { get; set; }
		public DateTime LastModifyDate { get; set; }
		public string LastModifyUserId { get; set; }
		public string LastModifyUserName { get; set; }
		public DateTime? CancelDate { get; set; }
		public string CancelUserName { get; set; }
		public string CancelUser { get; set; }
		public DateTime? SubmitDate { get; set; }
		public string SubmitUser { get; set; }
		public string SubmitUserName { get; set; }
		public DateTime? StartDate { get; set; }
		public string StartUserName { get; set; }
		public string StartUser { get; set; }
		public DateTime? CompleteDate { get; set; }
		public string CompleteUser { get; set; }
		public string CompleteUserName { get; set; }
		public string CloseUserName { get; set; }
		public DateTime? CloseDate { get; set; }
		public string CloseUser { get; set; }
		public DateTime? VoidDate { get; set; }
		public string VoidUserName { get; set; }
		public string VoidUser { get; set; }
		public Int32 Version { get; set; }
		public Boolean IsAutoStart { get; set; }
		public Boolean IsAutoRelease { get; set; }
		public string SubType { get; set; }
		public Decimal? ActVolume2 { get; set; }
		public Decimal? Weight { get; set; }
		public Decimal? ActWeight { get; set; }
		public Decimal? MaxPrice { get; set; }
		public string Phone { get; set; }
		public Boolean? IsAutoComplete { get; set; }
		public Boolean? IsASN { get; set; }
		public Decimal? TonnageWeight { get; set; }
		public Decimal ItemQty { get; set; }
        
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
            TOrderMaster another = obj as TOrderMaster;

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
