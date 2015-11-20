using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.WMS
{
    [Serializable]
    public partial class ShipPlan : EntityBase, IAuditable
    {
        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }
		public string Flow { get; set; }
		public string OrderNo { get; set; }
        public Int32 OrderSequence { get; set; }
        public Int32 OrderDetailId { get; set; }
        public DateTime StartTime { get; set; }
		public DateTime? WindowTime { get; set; }
		public string Item { get; set; }
		public string ItemDescription { get; set; }
		public string ReferenceItemCode { get; set; }
		public string Uom { get; set; }
		public string BaseUom { get; set; }
		public Decimal UnitCount { get; set; }
		public string UCDescription { get; set; }
		public Decimal OrderQty { get; set; }
		public Decimal ShipQty { get; set; }
        public com.Sconit.CodeMaster.OrderPriority Priority { get; set; }
		public string PartyFrom { get; set; }
		public string PartyFromName { get; set; }
		public string PartyTo { get; set; }
		public string PartyToName { get; set; }
		public string ShipFrom { get; set; }
		public string ShipFromAddress { get; set; }
		public string ShipFromTel { get; set; }
		public string ShipFromCell { get; set; }
		public string ShipFromFax { get; set; }
		public string ShipFromContact { get; set; }
		public string ShipTo { get; set; }
		public string ShipToAddress { get; set; }
		public string ShipToTel { get; set; }
		public string ShipToCell { get; set; }
		public string ShipToFax { get; set; }
		public string ShipToContact { get; set; }
		public string LocationFrom { get; set; }
		public string LocationFromName { get; set; }
		public string Dock { get; set; }
        public Boolean IsOccupyInventory { get; set; }
        public Boolean IsActive { get; set; }
		public Int32 CreateUserId { get; set; }
		public string CreateUserName { get; set; }
		public DateTime CreateDate { get; set; }
		public Int32 LastModifyUserId { get; set; }
		public string LastModifyUserName { get; set; }
		public DateTime LastModifyDate { get; set; }
        public Int32? CloseUserId { get; set; }
        public string CloseUserName { get; set; }
        public DateTime? CloseDate { get; set; }
		public Int32 Version { get; set; }
        
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
            ShipPlan another = obj as ShipPlan;

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
