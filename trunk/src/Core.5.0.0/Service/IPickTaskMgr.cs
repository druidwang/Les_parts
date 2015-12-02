using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.WMS;

namespace com.Sconit.Service
{
    public interface IPickTaskMgr
    {
        IList<PickTask> CreatePickTask(IList<ShipPlan> shipPlanList);

    }
}
