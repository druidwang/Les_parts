using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.Persistence;
using NHibernate.Expression;
using com.Sconit.TMS.Entity;
using com.Sconit.Service.Ext.Criteria;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class TonnageMgr : TonnageBaseMgr, ITonnageMgr
    {
        private static IList<Tonnage> cachedAllTonnage;
        public ICriteriaMgrE criteriaMgrE { get; set; }
        #region Customized Methods

        [Transaction(TransactionMode.Unspecified)]
        public IList<Tonnage> GetCacheAllTonnage()
        {
            if (cachedAllTonnage == null)
            {
                cachedAllTonnage = this.GetAllTonnage();
            }
            else
            {
                //检查Tonnage大小是否发生变化
                DetachedCriteria criteria = DetachedCriteria.For(typeof(Tonnage));
                criteria.SetProjection(Projections.ProjectionList().Add(Projections.Count("Code")));
                IList<int> count = this.criteriaMgrE.FindAll<int>(criteria);

                if (count[0] != cachedAllTonnage.Count)
                {
                    cachedAllTonnage = GetAllTonnage();
                }
            }

            return cachedAllTonnage;
        }

        //TODO: Add other methods here.
        [Transaction(TransactionMode.Unspecified)]
        public bool ExistsCode(string code)
        {
            if (this.LoadTonnage(code) != null)
            {
                return true;
            }

            return false;
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class TonnageMgrE : com.Sconit.TMS.Service.Impl.TonnageMgr, ITonnageMgrE
    {
    }
}

#endregion Extend Class