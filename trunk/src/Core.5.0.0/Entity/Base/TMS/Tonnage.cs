using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class Tonnage : EntityBase, IAuditable
    {
        #region O/R Mapping Properties
		
		public string Code { get; set; }
        public string Description { get; set; }
		public Decimal LoadVolume { get; set; }
		public string CreateUserName { get; set; }
        public Int32 CreateUserId { get; set; }
		public DateTime CreateDate { get; set; }
		public string LastModifyUserName { get; set; }
        public Int32 LastModifyUserId { get; set; }
		public DateTime LastModifyDate { get; set; }
		public Decimal LoadWeight { get; set; }
        
        #endregion

		public override int GetHashCode()
        {
			if (Code != null)
            {
                return Code.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            Tonnage another = obj as Tonnage;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.Code == another.Code);
            }
        } 
    }
	
}
