using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.TMS.Persistence;
using com.Sconit.Service;
using com.Sconit.TMS.Service.Ext;
using com.Sconit.TMS.Entity;
using com.Sconit.Service.Ext.Criteria;
using NHibernate.Expression;
using com.Sconit.TMS.Service.Util;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class TPriceListMgr : TPriceListBaseMgr, ITPriceListMgr
    {
        public ITPriceListDetMgrE priceListDetMgrE { get; set; }
        public ICriteriaMgrE criteriaMgrE { get; set; }

        #region Customized Methods

        [Transaction(TransactionMode.Unspecified)]
        public IList<TPriceList> GetTPriceList(string carrier)
        {
            return this.GetTPriceList(carrier, false);
        }
        
        [Transaction(TransactionMode.Unspecified)]
        public IList<TPriceList> GetTPriceList(string carrier, bool includeInactive)
        {
            DetachedCriteria detachedCriteria = DetachedCriteria.For<TPriceList>();
            detachedCriteria.Add(Expression.Eq("Carrier", carrier));
            if (!includeInactive)
            {
                detachedCriteria.Add(Expression.Eq("IsActive", true));
            }
            return criteriaMgrE.FindAll<TPriceList>(detachedCriteria);
        }

        [Transaction(TransactionMode.Requires)]
        public override void DeleteTPriceList(TPriceList priceList)
        {
            priceListDetMgrE.DeleteTPriceListDet(priceList.Code);
            entityDao.DeleteTPriceList(priceList);
        }

        [Transaction(TransactionMode.Requires)]
        public override void DeleteTPriceList(string code)
        {
            priceListDetMgrE.DeleteTPriceListDet(code);
            entityDao.DeleteTPriceList(code);
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class TPriceListMgrE : com.Sconit.TMS.Service.Impl.TPriceListMgr, ITPriceListMgrE
    {
    }
}

#endregion Extend Class