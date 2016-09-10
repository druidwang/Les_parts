using System;
using com.Sconit.Entity.SYS;
using System.ComponentModel.DataAnnotations;


namespace com.Sconit.Entity.FMS
{
    public partial class FacilityMaster 
    {
       

        #region Non O/R Mapping Properties
        [CodeDetailDescriptionAttribute(CodeMaster = com.Sconit.CodeMaster.CodeMaster.FacilityOrderStatus, ValueField = "Status")]
        [Display(Name = "FacilityMaster_Status", ResourceType = typeof(Resources.FMS.FacilityMaster))]
        public string FacilityStatusDescription { get; set; } 

        #endregion
    }
	
}