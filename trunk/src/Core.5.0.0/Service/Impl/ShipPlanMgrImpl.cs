using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.ORD;
using com.Sconit.Entity.Exception;
using com.Sconit.Entity.WMS;

namespace com.Sconit.Service.Impl
{
    public class ShipPlanMgrImpl : IShipPlanMgr
    {
        public IGenericMgr genericMgr { get; set; }

        public IList<ShipPlan> CreateShipPlan(string orderNo)
        {
            if (String.IsNullOrWhiteSpace(orderNo))
            {
                throw new TechnicalException("要货单号不能为空。");
            }

            OrderMaster orderMaster = this.genericMgr.FindAll<OrderMaster>("from OrderMaster where OrderNo = ?", orderNo).SingleOrDefault();

            if (orderMaster == null)
            {
                throw new BusinessException("要货单号{0}不能存在。", orderNo);
            }

            return CreateShipPlan(orderMaster);
        }

        public IList<ShipPlan> CreateShipPlan(OrderMaster orderMaster)
        {
            if (orderMaster == null)
            {
                throw new TechnicalException("要货单不能为空。");
            }

            #region 合法性校验
            if (orderMaster.Type != CodeMaster.OrderType.Distribution
                && orderMaster.Type != CodeMaster.OrderType.Transfer) 
            {
                throw new TechnicalException("要货单的类型不正确。");
            }

            if (orderMaster.Status != CodeMaster.OrderStatus.Submit)
            {
                throw new BusinessException("要货单{0}不是释放状态，不能创建发货任务。", orderMaster.OrderNo);
            }
            #endregion

            #region 加载订单明细
            if (orderMaster.OrderDetails == null)
            {
                orderMaster.OrderDetails = this.genericMgr.FindAll<OrderDetail>("from OrderDetail where OrderNo = ?", orderMaster.OrderNo);
            }
            #endregion

            #region 准备创建发货任务
            IList<ShipPlan> createdShipPlanList = this.genericMgr.FindAll<ShipPlan>("from ShipPlan where OrderNo = ?", orderMaster.OrderNo);
            IList<ShipPlan> shipPlanList = new List<ShipPlan>();
            DateTime dateTimeNow = DateTime.Now;

            foreach (OrderDetail orderDetail in orderMaster.OrderDetails)
            {
                decimal createdQty = createdShipPlanList.Where(p => p.OrderDetailId == orderDetail.Id).Sum(p => p.IsActive ? p.OrderQty : p.ShipQty);
                if (createdQty < orderDetail.OrderedQty)
                {
                    ShipPlan shipPlan = new ShipPlan();

                    shipPlan.Flow = orderMaster.Flow;
                    shipPlan.OrderNo = orderMaster.OrderNo;
                    shipPlan.OrderSequence = orderDetail.Sequence;
                    shipPlan.OrderDetailId = orderDetail.Id;
                    shipPlan.WindowTime = orderMaster.StartTime;
                    shipPlan.StartTime =  dateTimeNow; //todo 根据发运时刻表计算开始时间
                    shipPlan.Item =  orderDetail.Item;
                    shipPlan.ItemDescription =  orderDetail.ItemDescription;
                    shipPlan.ReferenceItemCode =  orderDetail.ReferenceItemCode;
                    shipPlan.Uom =  orderDetail.Uom;
                    shipPlan.BaseUom =  orderDetail.BaseUom;
                    shipPlan.UnitQty =  orderDetail.UnitQty;
                    shipPlan.UnitCount =  orderDetail.UnitCount;
                    shipPlan.UnitCountDescription =  orderDetail.UnitCountDescription;
                    shipPlan.OrderQty = orderDetail.OrderedQty - createdQty;
                    shipPlan.ShipQty =  0;
                    shipPlan.Priority =  orderMaster.Priority;
                    shipPlan.PartyFrom =  orderMaster.PartyFrom;
                    shipPlan.PartyFromName =  orderMaster.PartyFromName;
                    shipPlan.PartyTo =  orderMaster.PartyTo;
                    shipPlan.PartyToName =  orderMaster.PartyToName;
                    shipPlan.ShipFrom =  orderMaster.ShipFrom;
                    shipPlan.ShipFromAddress =  orderMaster.ShipFromAddress;
                    shipPlan.ShipFromTel =  orderMaster.ShipFromTel;
                    shipPlan.ShipFromCell =  orderMaster.ShipFromCell;
                    shipPlan.ShipFromFax =  orderMaster.ShipFromFax;
                    shipPlan.ShipFromContact =  orderMaster.ShipFromContact;
                    shipPlan.ShipTo =  orderMaster.ShipTo;
                    shipPlan.ShipToAddress =  orderMaster.ShipToAddress;
                    shipPlan.ShipToTel =  orderMaster.ShipToTel;
                    shipPlan.ShipToCell =  orderMaster.ShipToCell;
                    shipPlan.ShipToFax =  orderMaster.ShipToFax;
                    shipPlan.ShipToContact =  orderMaster.ShipToContact;
                    shipPlan.LocationFrom =  !String.IsNullOrWhiteSpace(orderDetail.LocationFrom) ? orderDetail.LocationFrom : orderMaster.LocationFrom;
                    shipPlan.LocationFromName =  !String.IsNullOrWhiteSpace(orderDetail.LocationFrom) ? orderDetail.LocationFromName : orderMaster.LocationFromName;
                    shipPlan.Dock =  orderMaster.Dock;
                    shipPlan.IsOccupyInventory =  true;
                    shipPlan.IsShipScanHu = orderMaster.IsShipScanHu;
                    shipPlan.IsActive = true;
                    shipPlan.Version =  1;

                    shipPlanList.Add(shipPlan);
                }
            }

            if (shipPlanList.Count == 0)
            {
                throw new BusinessException("要货单{0}已经创建了发货任务。", orderMaster.OrderNo);
            }
            #endregion

            #region 创建发货任务
            this.genericMgr.BulkInsert<ShipPlan>(shipPlanList);
            return shipPlanList;
            #endregion
        }

        public void CancelShipPlan(string orderNo)
        {
            throw new NotImplementedException();
        }

        public void CancelShipPlan(OrderMaster orderMaster)
        {
            throw new NotImplementedException();
        }
    }
}