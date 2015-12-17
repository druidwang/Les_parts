using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.SI.SD_WMS;
using AutoMapper;

namespace com.Sconit.Service.SI.Impl
{
    public class SD_WMSMgrImpl : BaseMgr, ISD_WMSMgr  
    {
        public List<PickTask> GetPickTaskByUser(int pickUserId)
        {
            IList<com.Sconit.Entity.WMS.PickTask> pickTaskList = this.genericMgr.FindAll<com.Sconit.Entity.WMS.PickTask>("from PickTask p where p.PickUserId=?", pickUserId);

            return Mapper.Map<List<Entity.WMS.PickTask>, List<Entity.SI.SD_WMS.PickTask>>(pickTaskList.ToList());
        }


        public void DoPick(List<Entity.SI.SD_INV.Hu> huList)
        {
            Dictionary<int, List<Entity.INV.Hu>> pickResult = new Dictionary<int, List<Entity.INV.Hu>>();
            foreach (var hu in huList)
            {
                if (pickResult.ContainsKey(hu.OrderDetId))
                {
                    pickResult[hu.OrderDetId].Add(Mapper.Map<Entity.SI.SD_INV.Hu, Entity.INV.Hu>(hu));
                }
                else
                {
                    var values = new List<Entity.INV.Hu>();
                    values.Add(Mapper.Map<Entity.SI.SD_INV.Hu, Entity.INV.Hu>(hu));
                    pickResult.Add(hu.OrderDetId, values);
                }
            }
        }
    }
}
