using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.TMS.Persistence;
using com.Sconit.Service;
using com.Sconit.Service.Ext.Criteria;
using com.Sconit.TMS.Service.Ext;
using com.Sconit.TMS.Entity;
using NHibernate.Expression;
using com.Sconit.TMS.Service.Util;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class TFlowMgr : TFlowBaseMgr, ITFlowMgr
    {
        public ITFlowDetMgrE flowDetMgrE { get; set; }
        public ICriteriaMgrE criteriaMgrE { get; set; }

        #region Customized Methods

        [Transaction(TransactionMode.Requires)]
        public override void DeleteTFlow(TFlow flow)
        {
            flowDetMgrE.DeleteTFlowDet(flow.Code);
            entityDao.DeleteTFlow(flow);
        }

        [Transaction(TransactionMode.Requires)]
        public override void DeleteTFlow(string code)
        {
            flowDetMgrE.DeleteTFlowDet(code);
            entityDao.DeleteTFlow(code);
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<TFlow> GetTFlow(string frontWaybillNo)
        {
            DetachedCriteria waybillCriteria = DetachedCriteria.For(typeof(Waybill));
            waybillCriteria.Add(Expression.Eq("WaybillNo", frontWaybillNo));
            waybillCriteria.Add(Expression.Not(Expression.Eq("Status", TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE)));
            waybillCriteria.Add(Expression.Not(Expression.Eq("Status", TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CANCEL)));
            //π˝¬ÀµÙ¡„–«‘Àµ•
            waybillCriteria.Add(Expression.Not(Expression.Eq("Type", TMSConstants.CODE_MASTER_TMS_TYPE_RST)));
            waybillCriteria.SetProjection(Projections.ProjectionList().Add(Projections.GroupProperty("ShipTo")));

            DetachedCriteria criteria = DetachedCriteria.For(typeof(TFlow));
            criteria.Add(Subqueries.PropertyIn("ShipFrom", waybillCriteria));

            return criteriaMgrE.FindAll<TFlow>(criteria);
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class TFlowMgrE : com.Sconit.TMS.Service.Impl.TFlowMgr, ITFlowMgrE
    {
    }
}

#endregion Extend Class