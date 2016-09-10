using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.INV
{
    [Serializable]
    public partial class ContainerHu : EntityBase
    {
        #region O/R Mapping Properties

        public int Id { get; set; }
        public string ContainerId { get; set; }
        public string HuId { get; set; }

        public Int32 CreateUserId { get; set; }
        public string CreateUserName { get; set; }
        public DateTime CreateDate { get; set; }
        public Int32 LastModifyUserId { get; set; }
        public string LastModifyUserName { get; set; }
        public DateTime LastModifyDate { get; set; }
        public Int32 Version { get; set; }

        #endregion

        public override int GetHashCode()
        {
            if (ContainerId != null)
            {
                return ContainerId.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            ContainerHu another = obj as ContainerHu;

            if (another == null)
            {
                return false;
            }
            else
            {
                return (this.ContainerId == another.ContainerId);
            }
        }
    }

}
