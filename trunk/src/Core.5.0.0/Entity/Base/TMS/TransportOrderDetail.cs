using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TransportOrderDetail : EntityBase
    {
        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }
		public string OrderNo { get; set; }
		public Int32 Sequence { get; set; }
		public string IpNo { get; set; }
		public Int32? OrderRouteId { get; set; }
		public Int32? EstPalletQty { get; set; }
		public Int32? PalletQty { get; set; }
		public Decimal? EstVolume { get; set; }
		public Decimal? Volume { get; set; }
		public Decimal? EstWeight { get; set; }
		public Decimal? Weight { get; set; }
		public Int32? EstBoxCount { get; set; }
		public Int32? BoxCount { get; set; }
		public DateTime? LoadTime { get; set; }
		public DateTime? UnloadTime { get; set; }
		public string PartyFrom { get; set; }
		public string PartyFromName { get; set; }
		public string PartyTo { get; set; }
		public string PartyToName { get; set; }
		public string ShipFrom { get; set; }
		public string ShipFromAddress { get; set; }
		public string ShipTo { get; set; }
		public string ShipToAddress { get; set; }
		public string Dock { get; set; }
		public Decimal? Distance { get; set; }
		public Boolean IsReceived { get; set; }
		public DateTime CreateDate { get; set; }
		public string CreateUserId { get; set; }
		public string CreateUserName { get; set; }
		public DateTime LastModifyDate { get; set; }
		public string LastModifyUserId { get; set; }
		public string LastModifyUserName { get; set; }
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
            TransportOrderDetail another = obj as TransportOrderDetail;

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
