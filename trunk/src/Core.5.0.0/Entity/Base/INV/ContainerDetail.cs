using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.INV
{
    [Serializable]
    public partial class ContainerDetail : EntityBase
    {
        #region O/R Mapping Properties
		
		public string ContId { get; set; }
		public string Container { get; set; }
		public string Location { get; set; }
		public Boolean IsEmpty { get; set; }
		public DateTime ActiveDate { get; set; }
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
			if (ContId != null)
            {
                return ContId.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            ContainerDetail another = obj as ContainerDetail;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.ContId == another.ContId);
            }
        } 
    }
	
}
