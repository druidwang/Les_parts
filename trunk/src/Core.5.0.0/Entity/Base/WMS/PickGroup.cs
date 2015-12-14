using System;
using System.ComponentModel.DataAnnotations;
using com.Sconit.CodeMaster;

namespace com.Sconit.Entity.WMS
{
    [Serializable]
    public partial class PickGroup : EntityBase
    {
        #region O/R Mapping Properties
		
		public string PickGroupCode { get; set; }
		public PickGroupType Type { get; set; }
		public string Description { get; set; }
		public Boolean IsActive { get; set; }
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
			if (PickGroupCode != null)
            {
                return PickGroupCode.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            PickGroup another = obj as PickGroup;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.PickGroupCode == another.PickGroupCode);
            }
        } 
    }
	
}
