﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace com.Sconit.Entity.SI.MES
{
    public class MES_Interface_MaterialIO
    {

        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }
		public string material_code { get; set; }
		public string bar_code { get; set; }
		public string batch_no { get; set; }
		public decimal quantity { get; set; }
		public string warehouse_code { get; set; }
		public string reservoir { get; set; }
		public string user_id { get; set; }
        public DateTime create_time { get; set; }
		public int op_type { get; set; }
		public string purchase_order_no { get; set; }
		public string purchase_line_no { get; set; }
		public string sale_order_no { get; set; }
		public string sale_line_no { get; set; }
		public string supplier_code { get; set; }
        public string customer_code { get; set; }
		public DateTime CreateDate { get; set; }
		public Int32 Status { get; set; }
		public string BatchNo { get; set; }
		public string UniqueCode { get; set; }
        
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
            MES_Interface_MaterialIO another = obj as MES_Interface_MaterialIO;

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
