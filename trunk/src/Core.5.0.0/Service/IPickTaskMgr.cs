using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.WMS;
using com.Sconit.Entity.INV;

namespace com.Sconit.Service
{
    public interface IPickTaskMgr
    {
        void CreatePickTask(IDictionary<int, decimal> shipPlanIdAndQtyDic);

        void PorcessPickResult4PickQty(Dictionary<int, decimal> pickResults);

        void PorcessPickResult4PickLotNoAndHu(Dictionary<int, string> pickResults);
    }
}
