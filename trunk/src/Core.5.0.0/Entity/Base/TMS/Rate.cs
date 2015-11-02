using com.Sconit.Entity;
using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class Rate : EntityBase,IAuditable
    {
        #region O/R Mapping Properties
        public Int32 Id { get; set; }

        public String Item { get; set; }

        public Decimal UnitCount { get; set; }

        public Decimal UnitWeight { get; set; }
	    public Decimal PackageWeight { get; set; }
	    public Decimal Height { get; set; }
	    public Decimal Lenght { get; set; }
	    public Decimal Width { get; set; }
	    public DateTime StartDate { get; set; }
	    public DateTime EndDate { get; set; }
	    public Decimal PriceByVolume { get; set; }
        public Decimal PriceByWeight { get; set; }

        public Int32 CreateUserId { get; set; }

        public string CreateUserName { get; set; }

        public DateTime CreateDate { get; set; }

        public Int32 LastModifyUserId { get; set; }

        public string LastModifyUserName { get; set; }

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
            Rate another = obj as Rate;

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
