using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.Persistence;
using com.Sconit.Service.Ext.Criteria;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class VehicleMgr : VehicleBaseMgr, IVehicleMgr
    {
        
        #region Customized Methods

        [Transaction(TransactionMode.Unspecified)]
        public bool ExistsCode(string code)
        {
            if (this.LoadVehicle(code) != null)
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
    public partial class VehicleMgrE : com.Sconit.TMS.Service.Impl.VehicleMgr, IVehicleMgrE
    {
    }
}

#endregion Extend Class