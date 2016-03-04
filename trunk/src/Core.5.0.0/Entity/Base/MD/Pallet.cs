using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.MD
{
    [Serializable]
    public partial class Pallet : EntityBase
    {
        #region O/R Mapping Properties
		
		public string Code { get; set; }
		public string Description { get; set; }
		public Decimal Volumn { get; set; }
		public Decimal Weight { get; set; }
		public Int32 CreateUserId { get; set; }
		public string CreateUserName { get; set; }
		public DateTime CreateDate { get; set; }
		public Int32 LastModifyUserId { get; set; }
		public string LastModifyUserName { get; set; }
		public DateTime LastModifyDate { get; set; }
        
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
            Pallet another = obj as Pallet;

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
