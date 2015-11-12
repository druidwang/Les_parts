using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TransportPriceListDetail : EntityBase, IAuditable
    {
        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }
		public string PriceList { get; set; }
        public string ShipFrom { get; set; }
        public string ShipFromDescription { get; set; }
        public string ShipTo { get; set; }
        public string ShipToDescription { get; set; }
        public com.Sconit.CodeMaster.TransportPricingMethod PricingMethod { get; set; }
        public DateTime StartDate { get; set; }
		public DateTime? EndDate { get; set; }
		public string Currency { get; set; }
		public Decimal UnitPrice { get; set; }
		public Boolean IsProvEst { get; set; }
		public string Tonnage { get; set; }
		public Decimal? MinPrice { get; set; }
        public Decimal? MaxPrice { get; set; }
        public Decimal? DeliveryFee { get; set; }
        public Decimal? LoadingFee { get; set; }
		public Decimal? ServiceFee { get; set; }
		public Decimal? StartQty { get; set; }
		public Decimal? EndQty { get; set; }
        public string CreateUserName { get; set; }
        public Int32 CreateUserId { get; set; }
        public DateTime CreateDate { get; set; }
        public string LastModifyUserName { get; set; }
        public Int32 LastModifyUserId { get; set; }
        public DateTime LastModifyDate { get; set; }
        #endregion

		public override int GetHashCode()
        {
			if (Id != 0)
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
            TransportPriceListDetail another = obj as TransportPriceListDetail;

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
