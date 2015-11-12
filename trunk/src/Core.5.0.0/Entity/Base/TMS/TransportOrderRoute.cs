using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TransportOrderRoute : EntityBase, IAuditable
    {
        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }
		public string OrderNo { get; set; }
		public Int32 Sequence { get; set; }
		public string ShipAddress { get; set; }
        public string ShipAddressDescription { get; set; }
		public Decimal? Distance { get; set; }
		public DateTime? EstDepartTime { get; set; }
		public DateTime? EstArriveTime { get; set; }
		public DateTime? DepartTime { get; set; }
		public string DepartInputUser { get; set; }
		public string DepartInputUserName { get; set; }
		public DateTime? ArriveTime { get; set; }
		public string ArriveInputUser { get; set; }
		public string ArriveInputUserName { get; set; }
		public Decimal? LoadRate { get; set; }
		public Decimal? WeightRate { get; set; }
		public DateTime CreateDate { get; set; }
        public Int32 CreateUserId { get; set; }
		public string CreateUserName { get; set; }
		public DateTime LastModifyDate { get; set; }
        public Int32 LastModifyUserId { get; set; }
		public string LastModifyUserName { get; set; }
		public Int32 Version { get; set; }
        public Boolean IsArrive { get; set; }
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
            TransportOrderRoute another = obj as TransportOrderRoute;

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
