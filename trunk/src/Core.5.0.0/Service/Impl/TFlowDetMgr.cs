using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.TMS.Persistence;
using com.Sconit.Service;
using com.Sconit.Service.Ext.Criteria;
using NHibernate.Expression;
using com.Sconit.TMS.Entity;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class TFlowDetMgr : TFlowDetBaseMgr, ITFlowDetMgr
    {
        public ICriteriaMgrE criteriaMgrE { get; set; }

        #region Customized Methods

        [Transaction(TransactionMode.Unspecified)]
        public IList<TFlowDet> GetTFlowDets(string flow, string carrier, string tonnage)
        {
            DetachedCriteria detachedCriteria = DetachedCriteria.For<TFlowDet>();
            detachedCriteria.Add(Expression.Eq("Flow", flow));
            detachedCriteria.Add(Expression.Eq("Carrier", carrier));
            if (!string.IsNullOrEmpty(tonnage))
            {
                detachedCriteria.Add(Expression.Eq("Tonnage", tonnage));
            }
            else
            {
                detachedCriteria.Add(Expression.Or(Expression.IsNull("Tonnage"), Expression.Eq("Tonnage", string.Empty)));
            }
            return criteriaMgrE.FindAll<TFlowDet>(detachedCriteria);
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<TFlowDet> GetActiveTFlowDets(string flow, string carrier, string tonnage)
        {
            DetachedCriteria detachedCriteria = DetachedCriteria.For<TFlowDet>();
            detachedCriteria.Add(Expression.Eq("Flow", flow));
            detachedCriteria.Add(Expression.Eq("Carrier", carrier));
            detachedCriteria.Add(Expression.Or(Expression.Eq("Tonnage", tonnage), Expression.Or(Expression.IsNull("Tonnage"), Expression.Eq("Tonnage", string.Empty))));
            detachedCriteria.AddOrder(Order.Desc("Tonnage"));
            return criteriaMgrE.FindAll<TFlowDet>(detachedCriteria);
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<TFlowDet> GetTFlowDet(string flow)
        {
            DetachedCriteria detachedCriteria = DetachedCriteria.For<TFlowDet>();
            detachedCriteria.Add(Expression.Eq("Flow", flow));

            return criteriaMgrE.FindAll<TFlowDet>(detachedCriteria);
        }

        [Transaction(TransactionMode.Requires)]
        public void DeleteTFlowDet(string flow)
        {
            var flowDet = this.GetTFlowDet(flow);
            if (flowDet == null || flowDet.Count == 0) return;
            foreach (var p in flowDet)
            {
                this.DeleteTFlowDet(p);
            }
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class TFlowDetMgrE : com.Sconit.TMS.Service.Impl.TFlowDetMgr, ITFlowDetMgrE
    {
    }
}

#endregion Extend Class