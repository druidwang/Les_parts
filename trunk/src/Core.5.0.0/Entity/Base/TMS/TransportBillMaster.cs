using com.Sconit.Entity;
using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    [Serializable]
    public partial class TransportBillMaster : EntityBase, IAuditable
    {
        #region O/R Mapping Properties

        [Display(Name = "BillMstr_BillNo", ResourceType = typeof(Resources.TMS.TransportBillMstr))]
        public string BillNo { get; set; }

        public string CarrierDescription { get; set; }

        [Display(Name = "BillMstr_Carrier", ResourceType = typeof(Resources.TMS.TransportBillMstr))]
        public string Carrier { get; set; }

        public com.Sconit.CodeMaster.BillType Type { get; set; }

        public CodeMaster.BillSubType SubType { get; set; }

        [Display(Name = "BillMstr_Status", ResourceType = typeof(Resources.TMS.TransportBillMstr))]
        public CodeMaster.BillStatus Status { get; set; }

        [Display(Name = "BillMstr_ExternalBillNo", ResourceType = typeof(Resources.TMS.TransportBillMstr))]
        public string ExternalBillNo { get; set; }

        public Boolean IsIncludeTax { get; set; }

        public string TaxCode { get; set; }


        public string RefBillNo { get; set; }

        [Display(Name = "BillMstr_BillAddress", ResourceType = typeof(Resources.TMS.TransportBillMstr))]
        public string BillAddress { get; set; }

        public string BillAddressDescription { get; set; }

        public string Currency { get; set; }

        public Decimal Discount { get; set; }

        public Decimal BillAmount { get; set; }

        public string CreateUserName { get; set; }

        public Int32 CreateUserId { get; set; }

        public DateTime CreateDate { get; set; }

        public string LastModifyUserName { get; set; }

        public Int32 LastModifyUserId { get; set; }

        public DateTime LastModifyDate { get; set; }

        public DateTime? CancelDate { get; set; }

        public string CancelUserName { get; set; }

        public Int32 CancelUser { get; set; }

        public DateTime? SubmitDate { get; set; }

        public Int32 SubmitUser { get; set; }

        public string SubmitUserName { get; set; }

        public string CloseUserName { get; set; }

        public DateTime CloseDate { get; set; }

        public Int32 CloseUser { get; set; }

        public DateTime? VoidDate { get; set; }

        public string VoidUserName { get; set; }

        public Int32 VoidUser { get; set; }

        public string InvoiceNo { get; set; }

        public DateTime? InvoiceDate { get; set; }

        #endregion

        public override int GetHashCode()
        {
            if (BillNo != null)
            {
                return BillNo.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            TransportBillMaster another = obj as TransportBillMaster;

            if (another == null)
            {
                return false;
            }
            else
            {
                return (this.BillNo == another.BillNo);
            }
        }
    }

}
