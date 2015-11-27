using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.WMS
{
    [Serializable]
    public partial class RepackTask : EntityBase
    {
        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }
        public string Item { get; set; }
        public string ItemDescription { get; set; }
        public string ReferenceItemCode { get; set; }
        public string Uom { get; set; }
        public string BaseUom { get; set; }
        public Decimal UnitQty { get; set; }
        public Decimal UnitCount { get; set; }
        public string UCDescription { get; set; }
        public Decimal Qty { get; set; }
        public Decimal RepackQty { get; set; }
		public string Location { get; set; }
		public CodeMaster.OrderPriority Priority { get; set; }
		public string RepackGroup { get; set; }
		public Int32? RepackUserId { get; set; }
		public string RepackUserName { get; set; }
		public DateTime StartTime { get; set; }
		public DateTime WindowTime { get; set; }
		public Boolean IsActive { get; set; }
		public Int32 CreateUserId { get; set; }
		public string CreateUserName { get; set; }
		public DateTime CreateDate { get; set; }
		public Int32 LastModifyUserId { get; set; }
		public string LastModifyUserName { get; set; }
		public DateTime LastModifyDate { get; set; }
		public Int32? CloseUser { get; set; }
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
            RepackTask another = obj as RepackTask;

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
