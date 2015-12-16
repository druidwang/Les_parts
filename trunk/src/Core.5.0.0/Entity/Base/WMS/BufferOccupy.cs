using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.WMS
{
    [Serializable]
    public partial class BufferOccupy : EntityBase
    {
        #region O/R Mapping Properties
		
		public Int32 BufferInventoryId { get; set; }
		public string OrderNo { get; set; }
		public Int32 OrderSequence { get; set; }
		public Int32 ShipPlanId { get; set; }
		public string TargetDock { get; set; }
		public Decimal OccupyQty { get; set; }
		public Int32 CreateUserId { get; set; }
		public string CreateUserName { get; set; }
		public DateTime CreateDate { get; set; }
		public Int32 LastModifyUserId { get; set; }
		public string LastModifyUserName { get; set; }
		public DateTime LastModifyDate { get; set; }
		public Int32 Version { get; set; }
        
        #endregion

		public override int GetHashCode()
        {
            if (BufferInventoryId != 0)
            {
                return BufferInventoryId.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            BufferOccupy another = obj as BufferOccupy;

            if (another == null)
            {
                return false;
            }
            else
            {
                return (this.BufferInventoryId == another.BufferInventoryId);
            }
        } 
    }
	
}
