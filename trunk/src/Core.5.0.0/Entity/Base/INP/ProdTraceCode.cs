using System;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Entity.INP
{
    [Serializable]
    public partial class ProdTraceCode : EntityBase
    {
        #region O/R Mapping Properties
		
		public string TraceCode { get; set; }
		public string OrderNo { get; set; }
		public Int32? OrderDetId { get; set; }
		public string Item { get; set; }
		public string ItemDesc { get; set; }
		public Int32 CreateUserId { get; set; }
		public string CreateUserName { get; set; }
		public DateTime CreateDate { get; set; }
		public Int32 LastModifyUserId { get; set; }
		public string LastModifyUserName { get; set; }
		public DateTime LastModifyDate { get; set; }
        
        #endregion

		public override int GetHashCode()
        {
			if (TraceCode != null)
            {
                return TraceCode.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            ProdTraceCode another = obj as ProdTraceCode;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.TraceCode == another.TraceCode);
            }
        } 
    }
	
}
