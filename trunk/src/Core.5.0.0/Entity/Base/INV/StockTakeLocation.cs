using System;
using System.ComponentModel.DataAnnotations;
using System.Collections.Generic;
namespace com.Sconit.Entity.INV
{
    [Serializable]
    public partial class StockTakeLocation : EntityBase, IAuditable
    {
        #region O/R Mapping Properties

        //[Display(Name = "Id", ResourceType = typeof(Resources.INV.StockTakeLocation))]
        public Int32 Id { get; set; }
        //[Display(Name = "StNo", ResourceType = typeof(Resources.INV.StockTakeLocation))]
        public string StNo { get; set; }
        [Display(Name = "StockTakeLocation_Location", ResourceType = typeof(Resources.INV.StockTakeLocation))]
        public string Location { get; set; }
        [Display(Name = "StockTakeLocation_LocationName", ResourceType = typeof(Resources.INV.StockTakeLocation))]
        public string LocationName { get; set; }
        //[Display(Name = "CreateUserId", ResourceType = typeof(Resources.INV.StockTakeLocation))]
        public Int32 CreateUserId { get; set; }
        //[Display(Name = "CreateUserName", ResourceType = typeof(Resources.INV.StockTakeLocation))]
        public string CreateUserName { get; set; }
        //[Display(Name = "CreateDate", ResourceType = typeof(Resources.INV.StockTakeLocation))]
        public DateTime CreateDate { get; set; }
        //[Display(Name = "LastModifyUserId", ResourceType = typeof(Resources.INV.StockTakeLocation))]
        public Int32 LastModifyUserId { get; set; }
        //[Display(Name = "LastModifyUserName", ResourceType = typeof(Resources.INV.StockTakeLocation))]
        public string LastModifyUserName { get; set; }
        //[Display(Name = "LastModifyDate", ResourceType = typeof(Resources.INV.StockTakeLocation))]
        public DateTime LastModifyDate { get; set; }

        [Display(Name = "StockTakeLocation_Bin", ResourceType = typeof(Resources.INV.StockTakeLocation))]
        public string Bins { get; set; }
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
            StockTakeLocation another = obj as StockTakeLocation;

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
