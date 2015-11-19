using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.WMS
{
    [Serializable]
    public partial class PickSchedule : EntityBase
    {
        #region O/R Mapping Properties
		
		public string PickScheduleNo { get; set; }
		public Decimal PickLeadTime { get; set; }
		public Decimal RepackLeadTime { get; set; }
		public Decimal SpreadLeadTime { get; set; }
		public Int32 CreateUserId { get; set; }
		public string CreateUserName { get; set; }
		public DateTime CreateDate { get; set; }
		public Int32 LastModifyUserId { get; set; }
		public string LastModifyUserName { get; set; }
		public DateTime LastModifyDate { get; set; }
        
        #endregion

		public override int GetHashCode()
        {
			if (PickScheduleNo != null)
            {
                return PickScheduleNo.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            PickSchedule another = obj as PickSchedule;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.PickScheduleNo == another.PickScheduleNo);
            }
        } 
    }
	
}
