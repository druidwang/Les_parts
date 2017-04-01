using System;
using System.ComponentModel.DataAnnotations;
using com.Sconit.Entity.SYS;

namespace com.Sconit.Entity.INV
{
    [Serializable]
    public partial class Pallet : EntityBase, IAuditable
    {
        #region O/R Mapping Properties

        [Display(Name = "Pallet_PalletCode", ResourceType = typeof(Resources.INV.Pallet))]
        public string PalletCode { get; set; }

        [Display(Name = "Pallet_HuId", ResourceType = typeof(Resources.INV.Pallet))]
        public string HuId { get; set; }

        public Int32 CreateUserId { get; set; }
        [Display(Name = "Pallet_CreateUserName", ResourceType = typeof(Resources.INV.Hu))]
        public string CreateUserName { get; set; }
        [Display(Name = "Pallet_CreateDate", ResourceType = typeof(Resources.INV.Hu))]
        public DateTime CreateDate { get; set; }

        public Int32 LastModifyUserId { get; set; }
        [Display(Name = "Pallet_LastModifyUserName", ResourceType = typeof(Resources.INV.Hu))]
        public string LastModifyUserName { get; set; }
        [Display(Name = "Pallet_LastModifyDate", ResourceType = typeof(Resources.INV.Hu))]
        public DateTime LastModifyDate { get; set; }
        #endregion


        public override int GetHashCode()
        {
            if (PalletCode != null)
            {
                return PalletCode.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }
   

        public override bool Equals(object obj)
        {
            Hu another = obj as Hu;

            if (another == null)
            {
                return false;
            }
            else
            {
                return (this.PalletCode == another.PalletCode);
            }
        }
    }

}
