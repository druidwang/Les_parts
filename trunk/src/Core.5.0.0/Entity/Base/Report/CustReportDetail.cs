using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

//TODO: Add other using statements here

namespace com.Sconit.Entity.Report
{
    [Serializable]
    public partial class CustReportDetail : EntityBase, IAuditable
    {
        #region O/R Mapping Properties
        public Int32 Id { get; set; }
        [Display(Name = "CustReport_Code", ResourceType = typeof(Resources.Report.CustReport))]
        public string Code { get; set; }
        [Display(Name = "CustReport_ParamType", ResourceType = typeof(Resources.Report.CustReport))]
        public string ParamType { get; set; }
        [Display(Name = "CustReport_ParamKey", ResourceType = typeof(Resources.Report.CustReport))]
        public string ParamKey { get; set; }
        [Display(Name = "CustReport_ParamText", ResourceType = typeof(Resources.Report.CustReport))]
        public string ParamText { get; set; }

        public Int32 CreateUserId { get; set; }

        [Display(Name = "CustReport_CreateUserName", ResourceType = typeof(Resources.Report.CustReport))]
        public string CreateUserName { get; set; }

        [Display(Name = "CustReport_CreateDate", ResourceType = typeof(Resources.Report.CustReport))]
        public DateTime CreateDate { get; set; }

        public Int32 LastModifyUserId { get; set; }

        [Display(Name = "CustReport_LastModifyUserName", ResourceType = typeof(Resources.Report.CustReport))]
        public string LastModifyUserName { get; set; }

        [Display(Name = "CustReport_LastModifyDate", ResourceType = typeof(Resources.Report.CustReport))]
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
            CustReportDetail another = obj as CustReportDetail;

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
