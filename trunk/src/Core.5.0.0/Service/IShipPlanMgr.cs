using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.ORD;

namespace com.Sconit.Service
{
    public interface IShipPlanMgr
    {
        void CreateShipPlan(OrderMaster orderMaster);

        void CancelShipPlan(OrderMaster orderMaster);


    }
}
