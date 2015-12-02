using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.ORD;
using com.Sconit.Entity.WMS;

namespace com.Sconit.Service
{
    public interface IShipPlanMgr
    {
        IList<ShipPlan> CreateShipPlan(string orderNo);

        IList<ShipPlan> CreateShipPlan(OrderMaster orderMaster);

        void CancelShipPlan(string orderNo);

        void CancelShipPlan(OrderMaster orderMaster);


    }
}
