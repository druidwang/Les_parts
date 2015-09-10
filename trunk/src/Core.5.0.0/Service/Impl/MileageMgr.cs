using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.Persistence;
using com.Sconit.TMS.Entity;
using com.Sconit.Service.Ext.Hql;
using System.Linq;
using com.Sconit.Entity.Exception;
//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class MileageMgr : MileageBaseMgr, IMileageMgr
    { }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class MileageMgrE : com.Sconit.TMS.Service.Impl.MileageMgr, IMileageMgrE
    {
    }
}

#endregion Extend Class