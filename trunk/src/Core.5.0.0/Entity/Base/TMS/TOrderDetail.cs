using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TOrderDetail : EntityBase
    {
        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }
		public string OrderNo { get; set; }
		public string FrontWaybillNo { get; set; }
		public string IpNo { get; set; }
		public Decimal UnitPack { get; set; }
		public Decimal Volume { get; set; }
		public Decimal PalletQty { get; set; }
		public string PartyFromDesc { get; set; }
		public string PartyFrom { get; set; }
		public string PartyTo { get; set; }
		public string PartyToDesc { get; set; }
		public DateTime? DepartTime { get; set; }
		public DateTime? ArriveTime { get; set; }
		public string CreateUserName { get; set; }
		public string CreateUserId { get; set; }
		public string ShipFrom { get; set; }
		public string ShipFromDesc { get; set; }
		public string ShipTo { get; set; }
		public string ShipToDesc { get; set; }
		public string Status { get; set; }
		public string Dock { get; set; }
		public Int32 Sequence { get; set; }
		public string Remark { get; set; }
		public Decimal Weight { get; set; }
		public Decimal ItemQty { get; set; }
        
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
            TOrderDetail another = obj as TOrderDetail;

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
