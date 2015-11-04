using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TransportPriceList : EntityBase
    {
        #region O/R Mapping Properties
		
		public string Code { get; set; }
		public string Description { get; set; }
        public com.Sconit.CodeMaster.TransportMode TransportMode { get; set; }
        public string Carrier { get; set; }
        public string CarrierName { get; set; }
		public Boolean IsActive { get; set; }
		public string CreateUserName { get; set; }
		public string CreateUserId { get; set; }
		public DateTime CreateDate { get; set; }
		public string LastModifyUserName { get; set; }
		public string LastModifyUserId { get; set; }
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
            TransportPriceList another = obj as TransportPriceList;

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
