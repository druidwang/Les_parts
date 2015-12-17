namespace com.Sconit.Service.SI
{
    using System;
    using System.Collections.Generic;
    using com.Sconit.Entity.SI.SD_WMS;

    public interface ISD_WMSMgr
    {
        List<PickTask> GetPickTaskByUser(int pickUserId);

        void DoPick(List<Entity.SI.SD_INV.Hu> huList);
    }
}
