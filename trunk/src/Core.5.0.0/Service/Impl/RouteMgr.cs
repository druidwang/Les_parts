using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.Persistence;
using com.Sconit.TMS.Entity;
using com.Sconit.Service.Ext.Criteria;
using NHibernate.Expression;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class RouteMgr : RouteBaseMgr, IRouteMgr
    {
        public ICriteriaMgrE criteriaMgrE { get; set; }

        #region Customized Methods

        [Transaction(TransactionMode.Unspecified)]
        public Route LoadRoute(string routeNo, string frontWaybillNo, string waybillNo)
        {
            DetachedCriteria criteria = DetachedCriteria.For(typeof(Route));

            criteria.Add(Expression.Eq("RouteNo", routeNo));

            if (string.IsNullOrEmpty(frontWaybillNo))
            {
                criteria.Add(Expression.Or(Expression.IsNull("Currency"), Expression.Eq("Currency", string.Empty)));
            }
            else
            {
                criteria.Add(Expression.Eq("FrontWaybillNo", frontWaybillNo));
            }

            criteria.Add(Expression.Eq("WaybillNo", waybillNo));

            var routeList = criteriaMgrE.FindAll<Route>(criteria);

            if (routeList == null || routeList.Count == 0) return null;
            return routeList[0];
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<Route> GetRoute(string routeNo)
        {
            DetachedCriteria criteria = DetachedCriteria.For(typeof(Route));
            criteria.Add(Expression.Eq("RouteNo", routeNo));
            criteria.AddOrder(Order.Asc("Id"));
            return criteriaMgrE.FindAll<Route>(criteria);
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class RouteMgrE : com.Sconit.TMS.Service.Impl.RouteMgr, IRouteMgrE
    {
    }
}

#endregion Extend Class