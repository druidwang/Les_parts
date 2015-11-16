using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.Entity.TMS;
using com.Sconit.Entity.Exception;
using com.Sconit.Entity.MD;
using com.Sconit.CodeMaster;
using com.Sconit.Entity.ORD;

namespace com.Sconit.Service.Impl
{
    [Transactional]
    public class TransportMgrImple : BaseMgr, ITransportMgr
    {
        public INumberControlMgr numberControlMgr { get; set; }
        public ISystemMgr systemMgr { get; set; }
        public IGenericMgr genericMgr { get; set; }

        #region public methods
        public TransportOrderMaster TransferFlow2Order(string flowCode)
        {
            if (string.IsNullOrEmpty(flowCode))
            {
                throw new BusinessException("运输路线代码不能为空");
            }

            TransportFlowMaster transportFlowMaster = this.genericMgr.FindAll<TransportFlowMaster>("from TransportFlowMaster where Code = ?", flowCode).SingleOrDefault();

            TransportOrderMaster transportOrderMaster = new TransportOrderMaster();

            return transportOrderMaster;
        }

        [Transaction(TransactionMode.Requires)]
        public string CreateTransportOrder(TransportOrderMaster transportOrderMaster, IList<string> ipNoList)
        {
            #region 是否生成运输单号校验
            if (!string.IsNullOrWhiteSpace(transportOrderMaster.OrderNo))
            {
                throw new TechnicalException("已经生成运输单号。");
            }
            #endregion

            #region 必输字段校验
            if (string.IsNullOrWhiteSpace(transportOrderMaster.Flow))
            {
                throw new BusinessException("运输路线代码不能为空");
            }

            if (string.IsNullOrWhiteSpace(transportOrderMaster.Vehicle))
            {
                throw new BusinessException("运输工具不能为空。");
            }

            if (string.IsNullOrWhiteSpace(transportOrderMaster.Carrier))
            {
                throw new BusinessException("承运商不能为空。");
            }
            #endregion

            #region 字段合法性校验
            TransportFlowMaster transportFlowMaster = this.genericMgr.FindAll<TransportFlowMaster>("from TransportFlowMaster where Code = ?", transportOrderMaster.Flow).SingleOrDefault();
            if (transportFlowMaster == null)
            {
                throw new BusinessException("运输路线{0}不存在。", transportOrderMaster.Flow);
            }
            else
            {
                transportOrderMaster.FlowDescription = transportFlowMaster.Description;
                transportOrderMaster.MinLoadRate = transportFlowMaster.MinLoadRate;
                transportOrderMaster.IsAutoRelease = transportFlowMaster.IsAutoRelease;
                transportOrderMaster.IsAutoStart = transportFlowMaster.IsAutoStart;
                transportOrderMaster.MultiSitePick = transportFlowMaster.MultiSitePick;
            }

            IList<TransportFlowRoute> transportFlowRouteList = this.genericMgr.FindAll<TransportFlowRoute>("from TransportFlowRoute where Flow = ? order by Sequence", transportOrderMaster.Flow);
            if (transportFlowRouteList == null || transportFlowRouteList.Count < 2)
            {
                throw new BusinessException("运输路线{0}没有维护足够的运输站点。", transportOrderMaster.Flow);
            }
            else
            {
                transportOrderMaster.ShipFrom = transportFlowRouteList.First().ShipAddress;
                transportOrderMaster.ShipFromAddress = transportFlowRouteList.First().ShipAddressDescription;
                transportOrderMaster.ShipTo = transportFlowRouteList.Last().ShipAddress;
                transportOrderMaster.ShipToAddress = transportFlowRouteList.Last().ShipAddressDescription;
            }

            Carrier carrier = genericMgr.FindAll<Carrier>("from Carrier where Code = ?", transportOrderMaster.Carrier).FirstOrDefault();

            if (carrier == null)
            {
                throw new BusinessException("承运商代码{0}不存在。", transportOrderMaster.Carrier);
            }
            else
            {
                transportOrderMaster.CarrierName = carrier.Name;
            }

            TransportFlowCarrier transportFlowCarrier = genericMgr.FindAll<TransportFlowCarrier>("from TransportFlowCarrier where Flow = ? and Carrier = ? and TransportMode = ?",
                new object[] { transportFlowMaster.Code, transportOrderMaster.Carrier, transportOrderMaster.TransportMode }).FirstOrDefault();

            if (transportFlowCarrier != null)
            {
                transportFlowCarrier.PriceList = transportFlowCarrier.PriceList;
                transportFlowCarrier.BillAddress = transportFlowCarrier.BillAddress;
            }

            if (!string.IsNullOrWhiteSpace(transportOrderMaster.Vehicle))
            {
                Vehicle vehicle = genericMgr.FindAll<Vehicle>("from Vehicle where Code = ?", transportOrderMaster.Vehicle).FirstOrDefault();

                if (vehicle == null)
                {
                    throw new BusinessException("运输工具{0}不存在。", transportOrderMaster.Vehicle);
                }

                if (vehicle.Carrier != carrier.Code)
                {
                    throw new BusinessException("运输工具{0}不属于承运商{1}。", transportOrderMaster.Vehicle, transportOrderMaster.Carrier);
                }

                Tonnage tonnage = genericMgr.FindAll<Tonnage>("from Tonnage where Code = ?", vehicle.Tonnage).FirstOrDefault();

                if (tonnage == null)
                {
                    throw new BusinessException("运输工具{0}的吨位代码{1}不存在。", vehicle.Code, transportOrderMaster.Tonnage);
                }

                transportOrderMaster.Tonnage = tonnage.Code;
                transportOrderMaster.LoadVolume = tonnage.LoadVolume;
                transportOrderMaster.LoadWeight = tonnage.LoadWeight;
                transportOrderMaster.DrivingNo = vehicle.DrivingNo;

                if (string.IsNullOrWhiteSpace(transportOrderMaster.Driver) && !string.IsNullOrWhiteSpace(vehicle.Driver))
                {
                    Driver driver = genericMgr.FindAll<Driver>("from Driver where Code = ?", vehicle.Driver).FirstOrDefault();
                    if (driver != null)
                    {
                        transportOrderMaster.Driver = driver.Code;
                        transportOrderMaster.DriverMobilePhone = driver.MobilePhone;
                        transportOrderMaster.LicenseNo = driver.LicenseNo;
                    }
                }
            }

            if (!string.IsNullOrWhiteSpace(transportOrderMaster.Driver))
            {
                Driver driver = genericMgr.FindAll<Driver>("from Driver where Code = ?", transportOrderMaster.Driver).FirstOrDefault();

                if (driver == null)
                {
                    throw new BusinessException("驾驶员{0}不存在。", transportOrderMaster.Driver);
                }

                transportOrderMaster.Driver = driver.Code;
                transportOrderMaster.DriverMobilePhone = driver.MobilePhone;
                transportOrderMaster.LicenseNo = driver.LicenseNo;
            }
            #endregion

            #region 准备运单
            string orderNo = numberControlMgr.GetTransportOrderNo(transportOrderMaster);
            if (ipNoList != null)
            {
                ipNoList = ipNoList.Distinct().ToArray();
            }

            IList<TransportOrderRoute> transportOrderRouteList = PrepareTransportOrderRoute(orderNo, transportOrderMaster.TransportMode, transportFlowRouteList);

            IList<TransportOrderDetail> transportOrderDetailList = PrepareTransportOrderDetail(orderNo, transportOrderMaster.TransportMode, transportOrderMaster.MultiSitePick, ipNoList, transportOrderRouteList);
            #endregion

            #region 创建运单
            this.genericMgr.Create(transportOrderMaster);
            foreach (TransportOrderRoute transportOrderRoute in transportOrderRouteList)
            {
                this.genericMgr.Create(transportOrderRoute);
            }

            foreach (TransportOrderDetail transportOrderDetail in transportOrderDetailList)
            {
                TransportOrderRoute transportOrderRouteFrom = transportOrderRouteList.Where(r => r.ShipAddress == transportOrderDetail.ShipFrom).OrderBy(r => r.Sequence).First();
                transportOrderDetail.OrderRouteFrom = transportOrderRouteFrom.Id;
                transportOrderDetail.OrderRouteTo = transportOrderRouteList.Where(r => r.ShipAddress == transportOrderDetail.ShipTo && r.Sequence > transportOrderRouteFrom.Sequence).OrderBy(r => r.Sequence).First().Id;
                this.genericMgr.Create(transportOrderDetail);
            }
            #endregion

            if (transportOrderMaster.IsAutoRelease)
            {
                ReleaseTransportOrderMaster(transportOrderMaster);
            }

            return orderNo;
        }

        [Transaction(TransactionMode.Requires)]
        public void AddTransportOrderRoute(string orderNo, int seq, string shipAddress)
        {
            if (string.IsNullOrWhiteSpace(orderNo))
            {
                throw new TechnicalException("运输单号不能为空。");
            }

            if (seq <= 0)
            {
                throw new TechnicalException("序号不能小于等于0。");
            }

            if (string.IsNullOrWhiteSpace(shipAddress))
            {
                throw new TechnicalException("站点不能为空。");
            }

            TransportOrderMaster transportOrderMaster = this.genericMgr.FindAll<TransportOrderMaster>("from TransportOrderMaster where OrderNo = ?", orderNo).SingleOrDefault();
            if (transportOrderMaster == null)
            {
                throw new BusinessException("运输单号{0}不存在。", orderNo);
            }

            if (transportOrderMaster.Status == TransportStatus.Close)
            {
                throw new BusinessException("运输单号{0}已经关闭，不能添加站点。", orderNo);
            }

            if (transportOrderMaster.Status == TransportStatus.Cancel)
            {
                throw new BusinessException("运输单号{0}已经取消，不能添加站点。", orderNo);
            }

            Address shipAddressInstance = genericMgr.FindAll<Address>("from Address where Code = ?", shipAddress).SingleOrDefault();

            if (shipAddressInstance == null)
            {
                throw new BusinessException("站点{0}不存在。", shipAddress);
            }

            if (!transportOrderMaster.MultiSitePick && seq == 1)
            {
                throw new BusinessException("不能改变运输单{0}的始发站点。", orderNo);
            }

            IList<TransportOrderRoute> transportOrderRouteList = genericMgr.FindAll<TransportOrderRoute>("from TransportOrderRoute where OrderNo = ? ", orderNo);

            var prevTransportOrderRoute = transportOrderRouteList.Where(r => r.Sequence < seq).SingleOrDefault();
            var nextTransportOrderRouteList = transportOrderRouteList.Where(r => r.Sequence >= seq);

            TransportOrderRoute transportOrderRoute = new TransportOrderRoute();
            transportOrderRoute.OrderNo = orderNo;
            transportOrderRoute.Sequence = nextTransportOrderRouteList.Count() > 0 ? seq : prevTransportOrderRoute.Sequence + 1;
            transportOrderRoute.ShipAddress = shipAddress;
            transportOrderRoute.ShipAddressDescription = shipAddressInstance.AddressContent;
            transportOrderRoute.Distance = prevTransportOrderRoute != null ?
                CalculateShipDistance(prevTransportOrderRoute.ShipAddress, transportOrderRoute.ShipAddress, transportOrderMaster.TransportMode)
                : 0;

            this.genericMgr.Create(transportOrderRoute);

            for (int i = 0; i < nextTransportOrderRouteList.Count(); i++)
            {
                TransportOrderRoute nextTransportOrderRoute = nextTransportOrderRouteList.ElementAt(i);
                nextTransportOrderRoute.Sequence++;
                if (i == 0)
                {
                    nextTransportOrderRoute.Distance = CalculateShipDistance(transportOrderRoute.ShipAddress, nextTransportOrderRoute.ShipAddress, transportOrderMaster.TransportMode);
                }

                this.genericMgr.Update(nextTransportOrderRoute);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void AddTransportOrderDetail(string orderNo, IList<string> ipNoList)
        {
            if (string.IsNullOrWhiteSpace(orderNo))
            {
                throw new TechnicalException("运输单号不能为空。");
            }

            TransportOrderMaster transportOrderMaster = this.genericMgr.FindAll<TransportOrderMaster>("from TransportOrderMaster where OrderNo = ?", orderNo).SingleOrDefault();
            if (transportOrderMaster == null)
            {
                throw new BusinessException("运输单号{0}不存在。", orderNo);
            }

            if (transportOrderMaster.Status == TransportStatus.Close)
            {
                throw new BusinessException("运输单号{0}已经关闭，不能添加ASN。", orderNo);
            }

            if (transportOrderMaster.Status == TransportStatus.Cancel)
            {
                throw new BusinessException("运输单号{0}已经取消，不能添加ASN。", orderNo);
            }

            if (ipNoList != null)
            {
                ipNoList = ipNoList.Distinct().ToArray();
            }

            IList<TransportOrderRoute> transportOrderRouteList = this.genericMgr.FindAll<TransportOrderRoute>("from TransportOrderRoute where OrderNo = ?", orderNo);
            IList<TransportOrderDetail> transportOrderDetailList = PrepareTransportOrderDetail(orderNo, transportOrderMaster.TransportMode, transportOrderMaster.MultiSitePick, ipNoList, transportOrderRouteList);

            foreach (TransportOrderDetail TransportOrderDetail in transportOrderDetailList)
            {
                this.genericMgr.Create(TransportOrderDetail);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void DeleteTransportOrderRoute(string orderNo, int transportOrderRouteId)
        {
            if (string.IsNullOrWhiteSpace(orderNo))
            {
                throw new TechnicalException("运输单号不能为空。");
            }

            if (transportOrderRouteId <= 0)
            {
                throw new TechnicalException("站点Id不能小于等于0。");
            }

            TransportOrderMaster transportOrderMaster = this.genericMgr.FindAll<TransportOrderMaster>("from TransportOrderMaster where OrderNo = ?", orderNo).SingleOrDefault();
            if (transportOrderMaster == null)
            {
                throw new BusinessException("运输单号{0}不存在。", orderNo);
            }

            if (transportOrderMaster.Status == TransportStatus.Close)
            {
                throw new BusinessException("运输单号{0}已经关闭，不能删除站点。", orderNo);
            }

            if (transportOrderMaster.Status == TransportStatus.Cancel)
            {
                throw new BusinessException("运输单号{0}已经取消，不能删除站点。", orderNo);
            }

            IList<TransportOrderRoute> transportOrderRouteList = genericMgr.FindAll<TransportOrderRoute>("from TransportOrderRoute where OrderNo = ? ", orderNo);

            TransportOrderRoute transportOrderRoute = transportOrderRouteList.Where(r => r.Id == transportOrderRouteId).SingleOrDefault();

            if (transportOrderRoute == null)
            {
                throw new BusinessException("删除的站点不存在。");
            }

            if (!transportOrderMaster.MultiSitePick && transportOrderRoute.Sequence == 1)
            {
                throw new BusinessException("不能删除运输单{0}的始发站点。", orderNo);
            }

            if (transportOrderRoute.IsArrive)
            {
                throw new BusinessException("已经过站点{0}，不能删除。", transportOrderRoute.ShipAddress);
            }

            IList<TransportOrderDetail> transportOrderDetailList = genericMgr.FindAll<TransportOrderDetail>("from TransportOrderDetail where RouteFromId = ? or RouteToId = ?", new object[] { transportOrderRouteId, transportOrderRouteId });

            if (transportOrderDetailList.Count() > 0)
            {
                throw new BusinessException("站点{0}有需要送货的ASN，不能删除。", transportOrderRoute.ShipAddress);
            }

            var prevTransportOrderRoute = transportOrderRouteList.Where(r => r.Sequence < transportOrderRoute.Sequence).SingleOrDefault();
            var nextTransportOrderRouteList = transportOrderRouteList.Where(r => r.Sequence > transportOrderRoute.Sequence);

            for (int i = 0; i < nextTransportOrderRouteList.Count(); i++)
            {
                TransportOrderRoute nextTransportOrderRoute = nextTransportOrderRouteList.ElementAt(i);
                nextTransportOrderRoute.Sequence--;
                if (i == 0)
                {
                    nextTransportOrderRoute.Distance = CalculateShipDistance(prevTransportOrderRoute.ShipAddress, nextTransportOrderRoute.ShipAddress, transportOrderMaster.TransportMode);
                }

                this.genericMgr.Update(nextTransportOrderRoute);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void DeleteTransportOrderDetail(string orderNo, IList<string> ipNoList)
        {
            if (string.IsNullOrWhiteSpace(orderNo))
            {
                throw new TechnicalException("运输单号不能为空。");
            }

            if (ipNoList == null || ipNoList.Count() == 0)
            {
                throw new TechnicalException("ASN号不能为空。");
            }

            TransportOrderMaster transportOrderMaster = this.genericMgr.FindAll<TransportOrderMaster>("from TransportOrderMaster where OrderNo = ?", orderNo).SingleOrDefault();
            if (transportOrderMaster == null)
            {
                throw new BusinessException("运输单号{0}不存在。", orderNo);
            }

            if (transportOrderMaster.Status == TransportStatus.Close)
            {
                throw new BusinessException("运输单号{0}已经关闭，不能删除ASN。", orderNo);
            }

            if (transportOrderMaster.Status == TransportStatus.Cancel)
            {
                throw new BusinessException("运输单号{0}已经取消，不能删除ASN。", orderNo);
            }

            if (ipNoList != null)
            {
                ipNoList = ipNoList.Distinct().ToArray();
            }

            StringBuilder selectTransportOrderDetailHql = null;
            StringBuilder selectIpMasterHql = null;
            IList<object> parms = new List<object>();
            foreach(string ipNo in ipNoList)
            {
                if (selectTransportOrderDetailHql == null)
                {
                    selectTransportOrderDetailHql = new StringBuilder("from TransportOrderDetail where OrderNo = ? and IpNo in (?");
                    selectIpMasterHql = new StringBuilder("from IpMaster where IpNo in (?");
                    parms.Add(orderNo);
                }
                else
                {
                    selectTransportOrderDetailHql.Append(",?");
                    selectIpMasterHql.Append(",?");
                }

                parms.Add(ipNo);
            }
            selectTransportOrderDetailHql.Append(")");
            selectIpMasterHql.Append(")");

            IList<TransportOrderDetail> transportOrderDetailList = genericMgr.FindAll<TransportOrderDetail>(selectTransportOrderDetailHql.ToString(), parms.ToArray());
            parms.RemoveAt(0);
            IList<IpMaster> ipMasterList = genericMgr.FindAll<IpMaster>(selectIpMasterHql.ToString(), parms.ToArray());

            foreach (string ipNo in ipNoList)
            {
                IpMaster ipMaster = ipMasterList.Where(i => i.IpNo == ipNo).SingleOrDefault();

                if (ipMaster == null)
                {
                    throw new BusinessException("ASN号{0}不存在。", ipNo);
                }

                if (transportOrderDetailList.Where(d => d.IpNo == ipNo).Count() == 0)
                {
                    throw new BusinessException("ASN{0}不在运输单{1}中，不能删除。", new object[] { ipNo, orderNo });
                }

                if (ipMaster.Status == IpStatus.InProcess || ipMaster.Status == IpStatus.Close)
                {
                    throw new BusinessException("ASN号{0}已经收货不能删除。", ipNo);
                }
            }

            foreach (TransportOrderDetail transportOrderDetail in transportOrderDetailList)
            {
                genericMgr.Delete(transportOrderDetail);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void ReleaseTransportOrderMaster(string orderNo)
        {

        }

        [Transaction(TransactionMode.Requires)]
        public void ReleaseTransportOrderMaster(TransportOrderMaster transportOrderMaster)
        {

        }
        #endregion

        #region private methods
        private IList<TransportOrderRoute> PrepareTransportOrderRoute(string orderNo, TransportMode transportMode, IList<TransportFlowRoute> transportFlowRouteList)
        {
            IList<TransportOrderRoute> transportOrderRouteList = new List<TransportOrderRoute>();
            TransportFlowRoute prevTransportFlowRoute = null;
            foreach (TransportFlowRoute transportFlowRoute in transportFlowRouteList)
            {
                TransportOrderRoute transportOrderRoute = new TransportOrderRoute();
                transportOrderRoute.OrderNo = orderNo;
                transportOrderRoute.Sequence = transportFlowRoute.Sequence;
                transportOrderRoute.ShipAddress = transportFlowRoute.ShipAddress;
                transportOrderRoute.ShipAddressDescription = transportFlowRoute.ShipAddressDescription;
                transportOrderRoute.Distance = prevTransportFlowRoute != null ?
                    CalculateShipDistance(prevTransportFlowRoute.ShipAddress, transportOrderRoute.ShipAddress, transportMode)
                    : 0;
                transportOrderRouteList.Add(transportOrderRoute);

                prevTransportFlowRoute = transportFlowRoute;
            }

            return transportOrderRouteList;
        }

        private IList<TransportOrderDetail> PrepareTransportOrderDetail(string orderNo, TransportMode transportMode, bool multiSitePick, IList<string> ipNoList, IList<TransportOrderRoute> transportOrderRouteList)
        {
            IList<TransportOrderDetail> transportOrderDetailList = new List<TransportOrderDetail>();
            if (ipNoList != null && ipNoList.Count > 0)
            {
                StringBuilder selectIpMasterHql = null;
                StringBuilder selectIpDetailHql = null;
                StringBuilder selectItemHql = null;
                StringBuilder verifyIpNoHql = null;
                IList<object> parms = new List<object>();
                foreach (string ipNo in ipNoList)
                {
                    if (selectIpMasterHql == null)
                    {
                        selectIpMasterHql = new StringBuilder("from IpMaster where IpNo in (?");
                        selectIpDetailHql = new StringBuilder("from IpDetail where IpNo in (?");
                        selectItemHql = new StringBuilder("from Item where code in (select Item from IpDetail where IpNo in (?");
                        verifyIpNoHql = new StringBuilder("select IpNo where TransportOrderDetail where IpNo in (?");
                    }
                    else
                    {
                        selectIpMasterHql.Append(", ?");
                        selectIpDetailHql.Append(", ?");
                        selectItemHql.Append(", ?");
                        verifyIpNoHql.Append(", ?");
                    }

                    parms.Add(ipNo);
                }
                selectIpMasterHql.Append(")");
                selectIpDetailHql.Append(")");
                selectItemHql.Append("))");
                verifyIpNoHql.Append(")");

                IList<IpMaster> ipMasterList = genericMgr.FindAll<IpMaster>(selectIpMasterHql.ToString(), parms.ToArray());
                IList<IpDetail> ipDetailList = genericMgr.FindAll<IpDetail>(selectIpDetailHql.ToString(), parms.ToArray());
                IList<Item> itemList = genericMgr.FindAll<Item>(selectItemHql.ToString(), parms.ToArray());
                IList<string> createdIpNoList = genericMgr.FindAll<string>(verifyIpNoHql.ToString(), parms.ToArray());

                if (createdIpNoList.Count > 0)
                {
                    throw new BusinessException("ASN号{0}已经创建了运输单。", String.Join(", ", createdIpNoList.ToArray()));
                }

                int seq = 1;
                foreach (string ipNo in ipNoList)
                {
                    IpMaster ipMaster = ipMasterList.Where(m => m.IpNo == ipNo).SingleOrDefault();
                    if (ipMaster == null)
                    {
                        throw new BusinessException("ASN号{0}不存在。", ipNo);
                    }

                    if (ipMaster.Status != IpStatus.Submit)
                    {
                        throw new BusinessException("ASN号{0}状态不是{1}不能添加至运输单。", ipNo, systemMgr.GetCodeDetailDescription(com.Sconit.CodeMaster.CodeMaster.IpStatus, ((int)IpStatus.Submit)).ToString());
                    }

                    TransportOrderRoute transportOrderRouteFrom =
                        transportOrderRouteList.Where(r => r.ShipAddress == ipMaster.ShipFrom && !r.IsArrive).OrderBy(r => r.Sequence).FirstOrDefault();

                    if (!multiSitePick && transportOrderRouteFrom.Sequence != 1)
                    {
                        throw new BusinessException("ASN号{0}发货地址不是运输单的始发站点。", ipNo);
                    }

                    if (transportOrderRouteFrom == null)
                    {
                        throw new BusinessException("ASN号{0}发货地址不是运输单经过的站点。", ipNo);
                    }

                    TransportOrderRoute transportOrderRouteTo =
                       transportOrderRouteList.Where(r => r.ShipAddress == ipMaster.ShipTo && !r.IsArrive && r.Sequence > transportOrderRouteFrom.Sequence).OrderBy(r => r.Sequence).FirstOrDefault();

                    if (transportOrderRouteTo == null)
                    {
                        throw new BusinessException("ASN号{0}收货地址不是运输单经过的站点。", ipNo);
                    }

                    TransportOrderDetail transportOrderDetail = new TransportOrderDetail();
                    transportOrderDetail.OrderNo = orderNo;
                    transportOrderDetail.Sequence = seq++;
                    transportOrderDetail.IpNo = ipNo;
                    transportOrderDetail.OrderRouteFrom = transportOrderRouteFrom.Id;
                    transportOrderDetail.OrderRouteTo = transportOrderRouteTo.Id;
                    transportOrderDetail.EstPalletQty = Convert.ToInt32(Math.Ceiling(ipDetailList.Sum(
                        d => (d.PalletLotSize > 0 ? (d.Qty / d.PalletLotSize) : ((itemList.Where(i => i.Code == d.Item).Single().PalletLotSize > 0 ? (d.Qty / itemList.Where(i => i.Code == d.Item).Single().PalletLotSize) : 0))))));
                    transportOrderDetail.EstVolume = ipDetailList.Sum(
                        d => (d.UnitCount > 0 ? (d.Qty / d.UnitCount) : ((itemList.Where(i => i.Code == d.Item).Single().UnitCount > 0 ? (d.Qty / itemList.Where(i => i.Code == d.Item).Single().UnitCount) : 0))) * d.PackageVolumn);
                    transportOrderDetail.EstVolume = ipDetailList.Sum(
                        d => (d.UnitCount > 0 ? (d.Qty / d.UnitCount) : ((itemList.Where(i => i.Code == d.Item).Single().UnitCount > 0 ? (d.Qty / itemList.Where(i => i.Code == d.Item).Single().UnitCount) : 0))) * d.PackageWeight);
                    transportOrderDetail.EstBoxCount = Convert.ToInt32(ipDetailList.Sum(
                        d => Math.Ceiling((d.UnitCount > 0 ? (d.Qty / d.UnitCount) : ((itemList.Where(i => i.Code == d.Item).Single().UnitCount > 0 ? (d.Qty / itemList.Where(i => i.Code == d.Item).Single().UnitCount) : 0))))));
                    transportOrderDetail.LoadTime = DateTime.Now;
                    transportOrderDetail.PartyFrom = ipMaster.PartyFrom;
                    transportOrderDetail.PartyFromName = ipMaster.PartyFromName;
                    transportOrderDetail.PartyTo = ipMaster.PartyTo;
                    transportOrderDetail.PartyToName = ipMaster.PartyToName;
                    transportOrderDetail.ShipFrom = ipMaster.ShipFrom;
                    transportOrderDetail.ShipFromAddress = ipMaster.ShipFromAddress;
                    transportOrderDetail.ShipFromTel = ipMaster.ShipFromTel;
                    transportOrderDetail.ShipFromCell = ipMaster.ShipFromCell;
                    transportOrderDetail.ShipFromFax = ipMaster.ShipFromFax;
                    transportOrderDetail.ShipFromContact = ipMaster.ShipFromContact;
                    transportOrderDetail.ShipTo = ipMaster.ShipTo;
                    transportOrderDetail.ShipToAddress = ipMaster.ShipToAddress;
                    transportOrderDetail.ShipToTel = ipMaster.ShipToTel;
                    transportOrderDetail.ShipToCell = ipMaster.ShipToCell;
                    transportOrderDetail.ShipToFax = ipMaster.ShipToFax;
                    transportOrderDetail.ShipToContact = ipMaster.ShipToContact;
                    transportOrderDetail.Dock = ipMaster.Dock;
                    transportOrderDetail.Distance =
                        CalculateShipDistance(transportOrderDetail.ShipFrom, transportOrderDetail.ShipTo, transportMode);
                    transportOrderDetail.IsReceived = false;
                }
            }

            return transportOrderDetailList;
        }

        private decimal? CalculateShipDistance(string shipFrom, string shipTo, TransportMode transportMode)
        {
            Mileage mileage = genericMgr.FindAll<Mileage>("from Mileage where ShipFrom = ? and ShipTo = ? and TransportMode = ? and IsActive = ?",
                new object[] { shipFrom, shipTo, transportMode, true }).FirstOrDefault();

            if (mileage != null)
            {
                return mileage.Distance;
            }
            else
            {
                return null;
            }
        }
        #endregion
    }
}
