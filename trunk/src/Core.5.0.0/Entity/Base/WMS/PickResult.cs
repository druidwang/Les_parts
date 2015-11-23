using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.WMS
{
    [Serializable]
    public partial class PickResult : EntityBase
    {
        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }
		public Int32 PickTaskId { get; set; }
		public string OrderNo { get; set; }
		public Int32? OrderSequence { get; set; }
		public Int32? ShipPlanId { get; set; }
		public string Item { get; set; }
		public string ItemDescription { get; set; }
		public string ReferenceItemCode { get; set; }
		public string Uom { get; set; }
		public string BaseUom { get; set; }
        public Decimal UnitQty { get; set; }
        public Decimal UnitCount { get; set; }
		public string UCDescription { get; set; }
		public Decimal PickQty { get; set; }
		public string Location { get; set; }
		public string Area { get; set; }
		public string Bin { get; set; }
		public string LotNo { get; set; }
		public string HuId { get; set; }
        public com.Sconit.CodeMaster.PickBy PickBy { get; set; }
		public Int32 PickUserId { get; set; }
		public string PickUserName { get; set; }
		public DateTime PickDate { get; set; }
		public Int32 CreateUserId { get; set; }
		public string CreateUserName { get; set; }
		public DateTime CreateDate { get; set; }
		public Boolean IsCancel { get; set; }
		public Int32 CancelUser { get; set; }
		public string CancelUserName { get; set; }
		public DateTime CancelDate { get; set; }
        
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
            PickResult another = obj as PickResult;

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
