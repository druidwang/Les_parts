using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TPriceListDetail : EntityBase
    {
        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }
		public string PriceList { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime? EndDate { get; set; }
		public string Currency { get; set; }
		public Decimal UnitPrice { get; set; }
		public Boolean IsProvEst { get; set; }
		public Decimal? MinLotSize { get; set; }
		public string Tonnage { get; set; }
		public Decimal? MinPrice { get; set; }
		public Decimal? SendFee { get; set; }
		public Decimal? InOutFee { get; set; }
		public Decimal? ServiceFee { get; set; }
		public string PricingMethod { get; set; }
		public Decimal? MonthlyQty { get; set; }
		public Decimal? MonthlyPrice { get; set; }
		public string StepUom { get; set; }
		public Decimal? StartQty { get; set; }
		public Decimal? EndQty { get; set; }
		public string ShipFromDesc { get; set; }
		public string ShipFrom { get; set; }
		public string ShipToDesc { get; set; }
		public string ShipTo { get; set; }
		public Decimal? MaxPrice { get; set; }
        
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
            TPriceListDetail another = obj as TPriceListDetail;

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
