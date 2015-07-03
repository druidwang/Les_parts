namespace com.Sconit.Service.SI.Impl
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using AutoMapper;
    using Castle.Services.Transaction;
    using com.Sconit.Entity.Exception;
    using com.Sconit.Entity.SI.SD_INV;
    using com.Sconit.Entity.VIEW;
    using com.Sconit.Service;
    using NHibernate;
    using com.Sconit.Utility;

    public class SD_InventoryMgrImpl : BaseMgr, com.Sconit.Service.SI.ISD_InventoryMgr
    {
        [Transaction(TransactionMode.Requires)]
        public Entity.SI.SD_INV.Hu GetHu(string huId)
        {
            try
            {
                HuStatus huStatus = huMgr.GetHuStatus(huId.ToUpper());
                var hu = Mapper.Map<HuStatus, Entity.SI.SD_INV.Hu>(huStatus);
                hu.AgingLocation = itemMgr.GetCacheItem(hu.Item).Location;
                //hu.HuOption = systemMgr.GetCodeDetailDescription(CodeMaster.CodeMaster.HuOption, (int)huStatus.HuOption);
                return hu;
            }
            catch (ObjectNotFoundException)
            {
                throw new BusinessException(string.Format("条码{0}不存在。", huId));
            }
        }

        [Transaction(TransactionMode.Requires)]
        public Entity.SI.SD_INV.Hu CloneHu(string huId, decimal qty)
        {
            try
            {
                Sconit.Entity.INV.Hu oldHu = genericMgr.FindById<Sconit.Entity.INV.Hu>(huId);
                return Mapper.Map<Sconit.Entity.INV.Hu, Entity.SI.SD_INV.Hu>(huMgr.CloneHu(oldHu, qty));
            }
            catch (ObjectNotFoundException)
            {
                throw new BusinessException("条码克隆失败。", huId);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public com.Sconit.Entity.SI.SD_INV.StockTakeMaster GetStockTake(string stNo)
        {
            Entity.INV.StockTakeMaster stockTakeMaster = genericMgr.FindById<Entity.INV.StockTakeMaster>(stNo);
            //if (stockTakeMaster.Status != CodeMaster.StockTakeStatus.InProcess)
            //{
            //    throw new BusinessException("盘点单的状态是{0}不能进行盘点",
            //        systemMgr.GetCodeDetailDescription(CodeMaster.CodeMaster.StockTakeStatus, ((int)stockTakeMaster.Status).ToString()));
            //}
            var stockTakeLocationList = genericMgr.FindAll<Entity.INV.StockTakeLocation>
                ("from StockTakeLocation where StNo=?", stNo);
            StockTakeMaster sdStockTakeMaster = Mapper.Map<Entity.INV.StockTakeMaster, StockTakeMaster>(stockTakeMaster);
            foreach (var location in stockTakeLocationList)
            {
                if (sdStockTakeMaster.Location == null)
                {
                    sdStockTakeMaster.Location = location.Location + ";";
                }
                else
                {
                    sdStockTakeMaster.Location += location.Location + ";";
                }
                if (!string.IsNullOrWhiteSpace(location.Bins))
                {
                    if (sdStockTakeMaster.CurrentBin == null)
                    {
                        sdStockTakeMaster.CurrentBin = location.Bins + ";";
                    }
                    else
                    {
                        sdStockTakeMaster.CurrentBin += location.Bins + ";";
                    }
                }
            }

            return sdStockTakeMaster;
        }

        /// <summary>
        /// 提交盘点结果
        /// </summary>
        /// <param name="stNo">盘点单号</param>
        /// <param name="StockTakeDetails">由多个<HuId,Bin>组成的数组</param>
        [Transaction(TransactionMode.Requires)]
        public void DoStockTake(string stNo, string[][] stockTakeDetails)
        {
            IList<Entity.INV.StockTakeDetail> StockTakeDetailList = new List<Entity.INV.StockTakeDetail>();
            stockTakeDetails = stockTakeDetails.Where(p => !string.IsNullOrWhiteSpace(p[0])).ToArray();
            var huIds = stockTakeDetails.Select(p => p[0]).Distinct().ToList();
            var huStatuses = huMgr.GetHuStatus(huIds).ToDictionary(d => d.HuId, d => d);

            foreach (var detail in stockTakeDetails)
            {
                Entity.VIEW.HuStatus huStatus = huStatuses.ValueOrDefault(detail[0]);
                Entity.INV.StockTakeDetail stockTakeDetail = new Entity.INV.StockTakeDetail
                {
                    HuId = detail[0],
                    Bin = detail[1],
                    Location = detail[2],
                    StNo = stNo,
                    QualityType = huStatus.QualityType,
                    Item = huStatus.Item,
                    ItemDescription = huStatus.ItemDescription,
                    Qty = huStatus.Qty,
                    BaseUom = huStatus.BaseUom,
                    Uom = huStatus.Uom,
                    UnitQty = huStatus.UnitQty,
                    LotNo = huStatus.LotNo,
                    IsCS = huStatus.IsConsignment
                };
                StockTakeDetailList.Add(stockTakeDetail);
            }
            stockTakeMgr.RecordStockTakeDetail(stNo, StockTakeDetailList);
        }

        [Transaction(TransactionMode.Requires)]
        public void DoPutAway(string huId, string binCode)
        {
            if (string.IsNullOrWhiteSpace(huId))
            {
                throw new Entity.Exception.BusinessException("条码不能为空");
            }
            if (string.IsNullOrWhiteSpace(binCode))
            {
                throw new Entity.Exception.BusinessException("库格不能为空");
            }

            var inventoryPutList = new List<Entity.INV.InventoryPut>();
            var inventoryPut = new Entity.INV.InventoryPut();

            inventoryPut.Bin = binCode;
            inventoryPut.HuId = huId;
            inventoryPutList.Add(inventoryPut);

            this.locationDetailMgr.InventoryPut(inventoryPutList);
        }

        //下架
        [Transaction(TransactionMode.Requires)]
        public void DoPickUp(string huId)
        {
            var inventoryPickList = new List<Entity.INV.InventoryPick>();
            var inventoryPick = new Entity.INV.InventoryPick();
            inventoryPick.HuId = huId;
            inventoryPickList.Add(inventoryPick);
            this.locationDetailMgr.InventoryPick(inventoryPickList);
        }

        [Transaction(TransactionMode.Requires)]
        public void DoPack(List<string> huIdList, string location, DateTime? effDate)
        {
            if (huIdList == null || huIdList.Count == 0)
            {
                throw new Entity.Exception.BusinessException("没有装箱的明细");
            }
            var inventoryPackList = new List<Entity.INV.InventoryPack>();
            foreach (var huId in huIdList)
            {
                var inventoryPack = new Entity.INV.InventoryPack();
                inventoryPack.HuId = huId;
                inventoryPack.Location = location;
                inventoryPackList.Add(inventoryPack);
            }
            if (effDate.HasValue)
            {
                locationDetailMgr.InventoryPack(inventoryPackList, effDate.Value);
            }
            else
            {
                locationDetailMgr.InventoryPack(inventoryPackList);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void DoUnPack(List<string> huIdList, DateTime? effDate)
        {
            if (huIdList == null || huIdList.Count == 0)
            {
                throw new Entity.Exception.BusinessException("没有拆箱的明细");
            }
            var inventoryPackList = new List<Entity.INV.InventoryUnPack>();
            foreach (var huId in huIdList)
            {
                var inventoryUnPack = new Entity.INV.InventoryUnPack();
                inventoryUnPack.HuId = huId;
                inventoryPackList.Add(inventoryUnPack);
            }
            if (effDate.HasValue)
            {
                locationDetailMgr.InventoryUnPack(inventoryPackList, effDate.Value);
            }
            else
            {
                locationDetailMgr.InventoryUnPack(inventoryPackList);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void DoRePack(List<string> oldHuList, List<string> newHuList, DateTime? effDate)
        {
            if (oldHuList == null || newHuList.Count == 0)
            {
                throw new Entity.Exception.BusinessException("没有翻箱前的明细");
            }
            if (newHuList == null || newHuList.Count == 0)
            {
                throw new Entity.Exception.BusinessException("没有翻箱后的明细");
            }
            var inventoryPackList = new List<Entity.INV.InventoryRePack>();
            foreach (var huId in oldHuList)
            {
                var inventoryUnPack = new Entity.INV.InventoryRePack();
                inventoryUnPack.HuId = huId;
                inventoryUnPack.Type = CodeMaster.RePackType.Out;
                inventoryPackList.Add(inventoryUnPack);
            }
            foreach (var huId in newHuList)
            {
                var inventoryUnPack = new Entity.INV.InventoryRePack();
                inventoryUnPack.HuId = huId;
                inventoryUnPack.Type = CodeMaster.RePackType.In;
                inventoryPackList.Add(inventoryUnPack);
            }
            if (effDate.HasValue)
            {
                locationDetailMgr.InventoryRePack(inventoryPackList, effDate.Value);
            }
            else
            {
                locationDetailMgr.InventoryRePack(inventoryPackList);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void InventoryFreeze(IList<string> huIdList)
        {
            this.locationDetailMgr.InventoryFreeze(huIdList);
        }

        [Transaction(TransactionMode.Requires)]
        public void InventoryUnFreeze(IList<string> huIdList)
        {
            this.locationDetailMgr.InventoryUnFreeze(huIdList);
        }

        #region 客户化代码
        [Transaction(TransactionMode.Requires)]
        public Hu GetDistHu(string huId)
        {
            try
            {
                HuStatus huStatus = huMgr.GetHuStatus(huId);
                com.Sconit.Entity.INV.HuMapping huMapping = this.genericMgr.FindAll<com.Sconit.Entity.INV.HuMapping>
                    ("from HuMapping h where h.HuId = ? and h.IsEffective = 0", huId).FirstOrDefault();
                Hu hu = Mapper.Map<HuStatus, Hu>(huStatus);
                hu.OrderNo = huMapping.OrderNo;
                hu.OrderDetId = huMapping.OrderDetId;
                hu.IsEffective = huMapping.IsEffective;
                return hu;
            }
            catch (ObjectNotFoundException)
            {
                throw new BusinessException(string.Format("没有找到条码{0}。", huId));
            }
        }


        [Transaction(TransactionMode.Requires)]
        public Hu ResolveHu(string extHuId)
        {
            if (extHuId == null && extHuId.Length != 17)
            {
                throw new BusinessException("关键件条码长度不正确。");
            }

            string supplierShortCode = extHuId.Substring(0, 4);
            string itemShortCode = extHuId.Substring(4, 5);
            string lotNo = extHuId.Substring(9, 4);

            com.Sconit.Entity.MD.Supplier supplier = this.genericMgr.FindAll<com.Sconit.Entity.MD.Supplier>("from Supplier where ShortCode = ?", supplierShortCode).SingleOrDefault();

            if (supplier == null)
            {
                throw new BusinessException("关键件条码中的供应商短代码{0}不存在。", supplierShortCode);
            }

            com.Sconit.Entity.MD.Item item = this.genericMgr.FindAll<com.Sconit.Entity.MD.Item>("from Item where ShortCode = ?", itemShortCode).SingleOrDefault();

            if (item == null)
            {
                throw new BusinessException("关键件条码中的零件短代码{0}不存在。", itemShortCode);
            }

            item.HuQty = 1;
            item.HuUnitCount = 1;
            item.HuUom = item.Uom;
            item.LotNo = lotNo;
            item.ManufactureParty = supplier.Code;

            return Mapper.Map<com.Sconit.Entity.INV.Hu, Hu>(this.huMgr.CreateHu(item, extHuId));
        }
        #endregion
    }
}
