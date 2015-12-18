using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.ORD;
using com.Sconit.Entity.Exception;
using com.Sconit.Entity.WMS;
using System.Data.SqlClient;
using System.Data;
using com.Sconit.Entity;
using com.Sconit.Entity.ACC;

namespace com.Sconit.Service.Impl
{
    public class ShipPlanMgrImpl : IShipPlanMgr
    {
        public IGenericMgr genericMgr { get; set; }

        public void CreateShipPlan(string orderNo)
        {
            User user = SecurityContextHolder.Get();
            genericMgr.ExecuteUpdateWithNativeQuery("exec USP_WMS_CreateShipPlan ?, ?, ?", new object[] { orderNo, user.Id, user.FullName });
        }

        public void CancelShipPlan(string orderNo)
        {
            throw new NotImplementedException();
        }
    }
}