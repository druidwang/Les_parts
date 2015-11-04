using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class Vehicle : EntityBase
    {
        #region O/R Mapping Properties
		
		public string Code { get; set; }
		public string Description { get; set; }
		public string DrivingNo { get; set; }
        public string Carrier { get; set; }
		public string Phone { get; set; }
        public string MobilePhone { get; set; }
        public string VIN { get; set; }
		public string EngineNo { get; set; }
		public string Address { get; set; }
		public string Fax { get; set; }
		public string Driver { get; set; }
		public string Tonnage { get; set; }
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
            Vehicle another = obj as Vehicle;

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
