using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.TMS.Persistence;
using com.Sconit.Service;
using NHibernate.Expression;
using com.Sconit.TMS.Entity;
using com.Sconit.Service.Ext.Criteria;
using com.Sconit.Entity;
using com.Sconit.Service.Ext.MasterData;
using com.Sconit.Entity.MasterData;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class TBillDetMgr : TBillDetBaseMgr, ITBillDetMgr
    {
        public ICriteriaMgrE criteriaMgrE { get; set; }


        #region Customized Methods

        [Transaction(TransactionMode.Unspecified)]
        public IList<TBillDet> GetTBillDet(string billNo)
        {
            DetachedCriteria criteria = DetachedCriteria.For(typeof(TBillDet));
            criteria.CreateAlias("Waybill", "w");
            if (!string.IsNullOrEmpty(billNo))
            {
                criteria.Add(Expression.Eq("BillNo", billNo));
            }
            criteria.AddOrder(Order.Desc("w.SubmitDate"));
            return criteriaMgrE.FindAll<TBillDet>(criteria);
        }


        [Transaction(TransactionMode.Unspecified)]
        public TBillDet TransferTActBill2TBillDet(TActBill actBill)
        {
            TBillDet billDetail = new TBillDet();
            billDetail.ActBill = actBill.Id;
            billDetail.Flow = actBill.Flow;
            billDetail.FlowDesc = actBill.FlowDesc;
            billDetail.FreightNo = actBill.FreightNo;
            billDetail.IsIncludeTax = actBill.IsIncludeTax;
            
            billDetail.EffDate = actBill.EffDate;
            billDetail.Waybill = actBill.Waybill;
            billDetail.PricingMethod = actBill.PricingMethod;
            billDetail.Currency = !string.IsNullOrEmpty(actBill.FreightNo) || string.IsNullOrEmpty(actBill.Flow) || string.IsNullOrEmpty(actBill.FlowCurrency) ? actBill.Currency : actBill.FlowCurrency;
            billDetail.TaxCode = actBill.TaxCode;
            billDetail.Discount = 0;
            billDetail.BillAmount = actBill.BillAmount.HasValue ? actBill.BillAmount.Value : 0;
            billDetail.BilledAmount = actBill.BilledAmount.HasValue ? actBill.BilledAmount.Value : 0;
          
            return billDetail;
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class TBillDetMgrE : com.Sconit.TMS.Service.Impl.TBillDetMgr, ITBillDetMgrE
    {
    }
}

#endregion Extend Class