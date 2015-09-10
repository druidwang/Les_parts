using com.Sconit.Entity;
using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TransportAddress : EntityBase, IAuditable
    {
        #region O/R Mapping Properties

        [Required(AllowEmptyStrings = false, ErrorMessageResourceName = "Errors_Common_FieldRequired", ErrorMessageResourceType = typeof(Resources.SYS.ErrorMessage))]
        [StringLength(50, ErrorMessageResourceName = "Errors_Common_FieldLengthExceed", ErrorMessageResourceType = typeof(Resources.SYS.ErrorMessage))]
        [Display(Name = "TransportAddress_Code", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string Code { get; set; }

        [Display(Name = "TransportAddress_Country", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string Country { get; set; }

        [Display(Name = "TransportAddress_Province", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string Province { get; set; }

        [Display(Name = "TransportAddress_City", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string City { get; set; }

        [Display(Name = "TransportAddress_District", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string District { get; set; }

        [Display(Name = "TransportAddress_Street", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string Street { get; set; }

        [Display(Name = "TransportAddress_Address", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string Address { get; set; }

        [Display(Name = "TransportAddress_Contacts", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string Contacts { get; set; }

        [Display(Name = "TransportAddress_PostCode", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string PostCode { get; set; }

        [Display(Name = "TransportAddress_Phone", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string Phone { get; set; }

        [Display(Name = "TransportAddress_MobilePhone", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string MobilePhone { get; set; }

        [Display(Name = "TransportAddress_Email", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string Email { get; set; }

        [Display(Name = "TransportAddress_Remark", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string Remark { get; set; }

        public Int32 CreateUserId { get; set; }
        [Display(Name = "TransportAddress_CreateUserName", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public string CreateUserName { get; set; }
        [Display(Name = "TransportAddress_CreateDate", ResourceType = typeof(Resources.TMS.TransportAddress))]
        public DateTime CreateDate { get; set; }

        public Int32 LastModifyUserId { get; set; }

        public string LastModifyUserName { get; set; }

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
            TransportAddress another = obj as TransportAddress;

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
