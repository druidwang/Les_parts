using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TFlowCarrier : EntityBase
    {
        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }
		public string Flow { get; set; }
		public Int32 Sequence { get; set; }
		public string Category { get; set; }
		public string CarrierDesc { get; set; }
		public string Carrier { get; set; }
		public string PriceList { get; set; }
		public string BillAddr { get; set; }
		public string CreateUserName { get; set; }
		public string CreateUserId { get; set; }
		public DateTime CreateDate { get; set; }
		public string LastModifyUserName { get; set; }
		public string LastModifyUserId { get; set; }
		public DateTime LastModifyDate { get; set; }
        
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
            TFlowCarrier another = obj as TFlowCarrier;

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
