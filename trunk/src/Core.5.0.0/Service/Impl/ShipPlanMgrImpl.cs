using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.ORD;
using com.Sconit.Entity.Exception;

namespace com.Sconit.Service.Impl
{
    public class ShipPlanMgrImpl
    {
        public void CreateShipPlan(OrderMaster orderMaster)
        {
            if (orderMaster == null)
            {
                throw new TechnicalException("要货单不能为空。");
            }

            if (orderMaster.Type != CodeMaster.OrderType.Distribution
                && orderMaster.Type != CodeMaster.OrderType.Transfer) 
            {
                throw new BusinessException("要货单类型不正确。");
            }
        }
    }
}
