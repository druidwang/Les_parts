using System;
using System.ComponentModel.DataAnnotations;

//TODO: Add other using statements here

namespace com.Sconit.Entity.SI.SAP
{
    public partial class SAPBom
    {
        #region Non O/R Mapping Properties

        //TODO: Add Non O/R Mapping Properties here. 
        [Display(Name = "SAPBom_Status", ResourceType = typeof(Resources.SI.SAPBom))]
        public string StatusDesc { get { return this.Status.HasValue && this.Status == 1 ? "�ɹ�" : "ʧ��"; } }

        #endregion
    }
}