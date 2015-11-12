using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TransportFlowCarrier : EntityBase, IAuditable
    {
        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }
		public string Flow { get; set; }
		public Int32 Sequence { get; set; }
        public com.Sconit.CodeMaster.TransportMode TransportMode { get; set; }
		public string Carrier { get; set; }
        public string CarrierName { get; set; }
        public string PriceList { get; set; }
		public string BillAddress { get; set; }
		public string CreateUserName { get; set; }
        public Int32 CreateUserId { get; set; }
		public DateTime CreateDate { get; set; }
		public string LastModifyUserName { get; set; }
        public Int32 LastModifyUserId { get; set; }
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
            TransportFlowCarrier another = obj as TransportFlowCarrier;

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
