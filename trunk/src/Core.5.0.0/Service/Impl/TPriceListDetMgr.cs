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
using com.Sconit.TMS.Service.Util;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class TPriceListDetMgr : TPriceListDetBaseMgr, ITPriceListDetMgr
    {
        public ICriteriaMgrE criteriaMgrE { get; set; }

        #region Customized Methods

        [Transaction(TransactionMode.Unspecified)]
        public TPriceListDet LoadTPriceListDet(string priceListCode, string pricingMethod, string currencyCode, string tonnage, string shipFrom, string shipTo, decimal? startQty, decimal? endQty, DateTime startDate)
        {
            DetachedCriteria detachedCriteria = DetachedCriteria.For<TPriceListDet>();
            detachedCriteria.Add(Expression.Eq("PriceList", priceListCode));
            detachedCriteria.Add(Expression.Eq("Currency", currencyCode));
            if (!string.IsNullOrEmpty(tonnage))
            {
                detachedCriteria.Add(Expression.Eq("Tonnage", tonnage));
            }
            else
            {
                detachedCriteria.Add(Expression.Or(Expression.Eq("Tonnage", string.Empty), Expression.IsNull("Tonnage")));
            }
            detachedCriteria.Add(Expression.Eq("PricingMethod", pricingMethod));
            detachedCriteria.Add(Expression.Eq("ShipFrom", shipFrom));
            detachedCriteria.Add(Expression.Eq("ShipTo", shipTo));
            //detachedCriteria.Add(Expression.Eq("StepUom", stepUom));
            detachedCriteria.Add(Expression.Eq("StartDate", startDate));

            //阶梯
            if (pricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_LADDERSTERE)
            {
                if (startQty.HasValue)
                {
                    detachedCriteria.Add(Expression.Eq("StartQty", startQty));
                }
                else
                {
                    detachedCriteria.Add(Expression.IsNull("StartQty"));
                }
                if (endQty.HasValue)
                {
                    detachedCriteria.Add(Expression.Eq("EndQty", endQty));
                }
                else
                {
                    detachedCriteria.Add(Expression.IsNull("EndQty"));
                }
            }

            IList<TPriceListDet> priceListDetailList = criteriaMgrE.FindAll<TPriceListDet>(detachedCriteria);
            if (priceListDetailList != null && priceListDetailList.Count > 0)
            {
                return priceListDetailList[0];
            }
            else
            {
                return null;
            }
        }

        [Transaction(TransactionMode.Unspecified)]
        protected IList<TPriceListDet> GetTPriceListDet(string priceListCode)
        {
            DetachedCriteria detachedCriteria = DetachedCriteria.For<TPriceListDet>();
            detachedCriteria.Add(Expression.Eq("PriceList", priceListCode));

            IList<TPriceListDet> priceListDetailList = criteriaMgrE.FindAll<TPriceListDet>(detachedCriteria);
            return priceListDetailList;
        }

        [Transaction(TransactionMode.Requires)]
        public void DeleteTPriceListDet(string priceList)
        {
            var priceLists = this.GetTPriceListDet(priceList);
            if (priceLists == null || priceLists.Count == 0) return;
            foreach (var p in priceLists)
            {
                this.DeleteTPriceListDet(p);
            }
        }

        /// <summary>
        /// 用于计算价格
        /// </summary>
        /// <param name="priceListCode"></param>
        /// <returns></returns>
        [Transaction(TransactionMode.Unspecified)]
        public TPriceListDet LoadTPriceListDet(string priceListCode, string pricingMethod, string currencyCode, string tonnage, string shipFrom, string shipTo, decimal qty, DateTime effDate)
        {
            DetachedCriteria detachedCriteria = DetachedCriteria.For<TPriceListDet>();
            detachedCriteria.Add(Expression.Eq("PriceList", priceListCode));
            detachedCriteria.Add(Expression.Eq("Currency", currencyCode));
            detachedCriteria.Add(Expression.Or(Expression.Eq("Tonnage", tonnage), Expression.Or(Expression.Eq("Tonnage", string.Empty), Expression.IsNull("Tonnage"))));
            detachedCriteria.Add(Expression.Eq("PricingMethod", pricingMethod));
            detachedCriteria.Add(Expression.Eq("ShipFrom", shipFrom));
            detachedCriteria.Add(Expression.Eq("ShipTo", shipTo));
            detachedCriteria.Add(Expression.Le("StartDate", effDate));
            detachedCriteria.Add(Expression.Or(Expression.Ge("EndDate", effDate), Expression.IsNull("EndDate")));
            //阶梯
            if (pricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_LADDERSTERE)
            {
                detachedCriteria.Add(Expression.Le("StartQty", qty));
                detachedCriteria.Add(Expression.Or(Expression.Ge("EndQty", qty), Expression.IsNull("EndQty")));
            }

            detachedCriteria.AddOrder(Order.Desc("Tonnage"));
            detachedCriteria.AddOrder(Order.Desc("StartDate"));
            detachedCriteria.AddOrder(Order.Desc("StartQty"));
            IList<TPriceListDet> priceListDetailList = criteriaMgrE.FindAll<TPriceListDet>(detachedCriteria);

            if (priceListDetailList != null && priceListDetailList.Count > 0)
            {
                return priceListDetailList[0];
            }
            else
            {
                return null;
            }
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class TPriceListDetMgrE : com.Sconit.TMS.Service.Impl.TPriceListDetMgr, ITPriceListDetMgrE
    {
    }
}

#endregion Extend Class