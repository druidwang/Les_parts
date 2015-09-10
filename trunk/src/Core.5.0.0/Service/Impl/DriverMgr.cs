using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.TMS.Persistence;using com.Sconit.Service;
using com.Sconit.Service.Ext.Criteria;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class DriverMgr : DriverBaseMgr, IDriverMgr
    {
        public ICriteriaMgrE criteriaMgrE { get; set; }

        #region Customized Methods

        [Transaction(TransactionMode.Unspecified)]
        public bool ExistsCode(string code)
        {
            if (this.LoadDriver(code) != null)
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
    public partial class DriverMgrE : com.Sconit.TMS.Service.Impl.DriverMgr, IDriverMgrE
    {
    }
}

#endregion Extend Class