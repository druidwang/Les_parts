using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.SI.SD_WMS;
using AutoMapper;
using Castle.Services.Transaction;
using com.Sconit.Entity.VIEW;
using LeanEngine.Entity;
using NHibernate;

namespace com.Sconit.Service.SI.Impl
{
    public class SD_WMSMgrImpl : BaseMgr, ISD_WMSMgr  
    {
        public IPickTaskMgr pickTaskMgr { get; set; }

        public List<PickTask> GetPickTaskByUser(int pickUserId)
        {
            IList<com.Sconit.Entity.WMS.PickTask> pickTaskList = this.genericMgr.FindAll<com.Sconit.Entity.WMS.PickTask>("from PickTask p where p.PickUserId=?", pickUserId);

            return Mapper.Map<List<Entity.WMS.PickTask>, List<Entity.SI.SD_WMS.PickTask>>(pickTaskList.ToList());
        }

        [Transaction(TransactionMode.Requires)]
        public Entity.SI.SD_INV.Hu GetPickHu(string huId)
        {
            try
            {
                HuStatus huStatus = huMgr.GetHuStatus(huId.ToUpper());
                var hu = Mapper.Map<HuStatus, Entity.SI.SD_INV.Hu>(huStatus);
                if (string.IsNullOrEmpty(hu.Location))
                {
                    throw new BusinessException(string.Format("条码{0}不在库存中。", huId));
                }
                var occupy = this.genericMgr.FindAll<com.Sconit.Entity.WMS.BufferInventory>("select bi.* from BufferInventory as bi where bi.HuId = ? ", hu.HuId);
                if (occupy != null && occupy.Count > 0)
                {
                    throw new BusinessException(string.Format("条码{0}已被其他拣货任务占用。", huId));
                }
                return hu;
            }
            catch (ObjectNotFoundException)
            {
                throw new BusinessException(string.Format("条码{0}不存在。", huId));
            }
        }


        [Transaction(TransactionMode.Requires)]
        public Entity.SI.SD_INV.Hu GetDeliverMatchHu(string huId)
        {
            try
            {
                HuStatus huStatus = huMgr.GetHuStatus(huId.ToUpper());
                var hu = Mapper.Map<HuStatus, Entity.SI.SD_INV.Hu>(huStatus);
                if (string.IsNullOrEmpty(hu.Location))
                {
                    throw new BusinessException(string.Format("条码{0}不在库存中。", huId));
                }
                var occupy = this.genericMgr.FindAll<com.Sconit.Entity.WMS.BufferInventory>("select bi.* from BufferInventory as bi where bi.HuId = ? ", hu.HuId);
                if (occupy == null && occupy.Count == 0)
                {
                    throw new BusinessException(string.Format("条码{0}未被拣货任务占用。", huId));
                }
                hu.AgingLocation = occupy.FirstOrDefault().Dock;
                return hu;
            }
            catch (ObjectNotFoundException)
            {
                throw new BusinessException(string.Format("条码{0}不存在。", huId));
            }
        }

        public void DoPickTask(List<Entity.SI.SD_INV.Hu> huList)
        {
            try
            {
                Dictionary<int, List<string>> pickResult = new Dictionary<int, List<string>>();
                foreach (var hu in huList)
                {
                    if (pickResult.ContainsKey(hu.OrderDetId))
                    {
                        pickResult[hu.OrderDetId].Add(hu.HuId);
                    }
                    else
                    {
                        var values = new List<string>();
                        values.Add(hu.HuId);
                        pickResult.Add(hu.OrderDetId, values);
                    }
                }
                pickTaskMgr.PorcessPickResult4PickLotNoAndHu(pickResult);
            }
            catch (Exception ex)
            {
                throw new BusinessException(ex.Message);
            }
        }


        public Entity.SI.SD_WMS.DeliverBarCode GetDeliverBarCode(string barCode)
        { 
            try
            {
                var deliverBarCode = this.genericMgr.FindById<Entity.WMS.DeliveryBarCode>(barCode);
                if (string.IsNullOrEmpty(deliverBarCode.HuId))
                {
                    throw new BusinessException(string.Format("配送标签{0}已关联条码{1}。", barCode, deliverBarCode.HuId));
                }
                if (deliverBarCode.IsActive == false)
                {
                    throw new BusinessException(string.Format("配送标签{0}已经失效。", barCode));
                }
                return Mapper.Map<Entity.WMS.DeliveryBarCode, Entity.SI.SD_WMS.DeliverBarCode>(deliverBarCode);
            }
            catch (ObjectNotFoundException)
            {
                throw new BusinessException(string.Format("配送标签{0}不存在。", barCode));
            }
        }

        public void MatchDCToHU(string huId, string barCode)
        {
            try
            {
                var deliverBarCode = this.genericMgr.FindById<Entity.WMS.DeliveryBarCode>(barCode);
                deliverBarCode.IsActive = false;
                deliverBarCode.HuId = huId;
                this.genericMgr.Update(deliverBarCode);

                if (!string.IsNullOrEmpty(huId))
                {
                    var bufferInventory = this.genericMgr.FindAll<com.Sconit.Entity.WMS.BufferInventory>("select bi.* from BufferInventory as bi where bi.HuId = ? ", huId).FirstOrDefault();
                    bufferInventory.Dock = deliverBarCode.Dock;
                    this.genericMgr.Update(bufferInventory);
                }
            }
            catch (ObjectNotFoundException)
            {
                throw new BusinessException(string.Format("配送标签{0}不存在。", barCode));
            }
        }

        public void TransferToDock(List<string> huIds, string dock)
        {
            try
            {
                string sql = "update BufferInventory set Dock = ? where HuId in(";
                List<object> param = new List<object>();
                param.Add(dock);
                for(int i=0;i< huIds.Count;++i)
                {
                    if(i==0)
                    {
                        sql+="?";
                    }
                    else
                    {
                        sql+=",?";
                    }
                    param.Add(huIds[i]);
                }
                this.genericMgr.FindAllWithNativeSql(sql,param);
            }
            catch (Exception ex)
            {
                throw new BusinessException(ex.Message);
            }
        }
    }
}
