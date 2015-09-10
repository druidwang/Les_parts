using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.TMS.Persistence;
using com.Sconit.Service;
using com.Sconit.TMS.Entity;
using com.Sconit.Service.Ext.Criteria;
using NHibernate.Expression;
using com.Sconit.TMS.Service.Util;
using com.Sconit.Service.Ext.MasterData;
using com.Sconit.TMS.Service.Ext;
using com.Sconit.Entity;
using com.Sconit.Entity.Exception;
using com.Sconit.Entity.MasterData;
using com.Sconit.Utility;
using com.Sconit.Service.Ext.Distribution;
using com.Sconit.Entity.Distribution;
using com.Sconit.Persistence.Distribution;
using System.Linq;
using System.Data.SqlClient;
using System.Data;
using com.Sconit.Service.Ext;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{

    [Transactional]
    public class WaybillMgr : WaybillBaseMgr, IWaybillMgr
    {
        public IEntityPreferenceMgrE entityPreferenceMgrE { get; set; }
        public ICriteriaMgrE criteriaMgrE { get; set; }
        public INumberControlMgrE numberControlMgrE { get; set; }
        public IFreightMgrE freightMgrE { get; set; }
        public IDriverMgrE driverMgrE { get; set; }
        public IVehicleMgrE vehicleMgrE { get; set; }
        public ITActBillMgrE actbillMgrE { get; set; }
        public ITPriceListMgrE priceListMgrE { get; set; }
        public ISqlHelperMgrE sqlHelperMgr { get; set; }
        public ITPriceListDetMgrE priceListDetMgrE { get; set; }
        public ICarrierMgrE carrierMgrE { get; set; }
        public ITFlowMgrE flowMgrE { get; set; }
        public ITFlowDetMgrE flowDetMgrE { get; set; }
        public IWaybillDetMgrE waybillDetMgrE { get; set; }
        public IPlaceDetMgrE placeDetMgrE { get; set; }

        public ITonnageMgrE tonnageMgrE { get; set; }
        //public IInProcessLocationMgrE ipMgrE { get; set; }
        public IInProcessLocationDao ipDao { get; set; }

        private string[] Waybill2WaybillCloneFields = new string[] 
            { 
                "RefNo",
                "ExtNo",
                "Carrier",
                "CarrierDesc",
                //"ShipFrom",
                //"ShipFromDesc",
                //"ShipTo",
                //"ShipToDesc",
                //"Flow",
                //"FlowDesc",
                "Category",
                "WinTime",
                "SettleTime",
                //"IsFree",                
                "Tonnage",             
                "Remark",
                "MorePlace",
                "SubType",
                "ActVolume",
                "ActVolume2",
                "ActWeight",
                "Weight",
                "ActPalletQty",
                "ActUnitPack",
                "Phone"
                //"PriceList",
            };

        private string[] Waybill2RouteCloneFields = new string[] 
            {  
                "WaybillNo",
                "ShipFrom",
                "ShipFromDesc",
                "ShipTo",
                "ShipToDesc",
                "Flow",
                "FlowDesc",
                "Carrier",
                "CarrierDesc",
                "Type",
                "CreateDate",
                "CreateUser",
                "CreateUserNm"
            };

        private string[] Flow2WaybillCloneFields = new string[] 
            {                 
                "ShipFrom",
                "ShipFromDesc",
                "ShipTo",
                "ShipToDesc",
                "Flow",
                "PalletVolume",
                "IsAutoStart",
                "StartDutyCycle",
                "IsAutoComplete",
                "IsMorePlace",
                "IsASN"
                //通过页面选
                //"IsAutoRelease"
            };


        #region Customized Methods

        [Transaction(TransactionMode.Unspecified)]
        public Waybill CheckAndLoadWaybill(string waybillNo)
        {
            Waybill waybill = this.LoadWaybill(waybillNo);
            if (waybill != null)
            {
                return waybill;
            }
            else
            {
                throw new BusinessErrorException("TMS.Error.WaybillNoNotExist", waybillNo);
            }
        }
        [Transaction(TransactionMode.Requires)]
        public void StartWaybill(string waybillNo, User user)
        {
            StartWaybill(waybillNo, string.Empty, user);
        }
        [Transaction(TransactionMode.Requires)]
        public void StartWaybill(string waybillNo, string remark, User user)
        {
            var waybill = this.CheckAndLoadWaybill(waybillNo);
            if (waybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_SUBMIT)
            {
                throw new BusinessErrorException("TMS.Waybill.Error.StatusErrorWhenStart", waybill.Status, waybill.WaybillNo);
            }

            waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_INPROCESS;

            DateTime now = DateTime.Now;
            waybill.StartDate = now;
            waybill.StartUser = user.Code;
            waybill.StartUserNm = user.Name;
            waybill.LastModifyDate = now;
            waybill.LastModifyUser = user.Code;
            waybill.LastModifyUserNm = user.Name;
            waybill.Remark = remark;
            this.UpdateAuto(waybill, now, user);
            this.UpdateWaybill(waybill);
        }

        [Transaction(TransactionMode.Requires)]
        public void CancelWaybill(string waybillNo, string remark, User user)
        {
            var waybill = this.CheckAndLoadWaybill(waybillNo);
            if (waybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_SUBMIT && waybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_INPROCESS)
            {
                throw new BusinessErrorException("TMS.Waybill.Error.StatusErrorWhenCancel", waybill.Status, waybill.WaybillNo);
            }
            waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CANCEL;

            DateTime now = DateTime.Now;
            waybill.CancelDate = now;
            waybill.CancelUser = user.Code;
            waybill.CancelUserNm = user.Name;
            waybill.LastModifyDate = now;
            waybill.LastModifyUser = user.Code;
            waybill.LastModifyUserNm = user.Name;
            waybill.Remark = remark;
            this.UpdateWaybill(waybill);
            //恢复运费单
            if (!string.IsNullOrEmpty(waybill.FreightNo))
            {
                this.freightMgrE.OpenFreight(waybill.FreightNo, user.Code, user.Name);
            }
            var waybillDetList = this.waybillDetMgrE.GetWaybillDet(waybillNo);
            if (waybillDetList != null && waybillDetList.Count > 0)
            {
                //更新明细
                foreach (WaybillDet waybillDet in waybillDetList)
                {
                    waybillDet.WaybillNo = waybill.WaybillNo;

                    this.waybillDetMgrE.CreateWaybillDet(waybillDet);

                    InProcessLocation ip = ipDao.LoadInProcessLocation(waybillDet.IpNo);
                    ip.WaybillNo = string.Empty;
                    ipDao.UpdateInProcessLocation(ip);
                }
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void CloseWaybill(string billNo, DateTime effDate, User user)
        {
            IList<Waybill> waybillList = this.GetWaybill(billNo);
            foreach (var waybill in waybillList)
            {
                if (waybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_COMPLETE)
                {
                    throw new BusinessErrorException("TMS.Waybill.Error.StatusErrorWhenClose", waybill.Status, waybill.WaybillNo);
                }
                waybill.CloseDate = effDate;
                waybill.CloseUser = user.Code;
                waybill.CloseUserNm = user.Name;
                waybill.LastModifyDate = effDate;
                waybill.LastModifyUser = user.Code;
                waybill.LastModifyUserNm = user.Name;
                waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CLOSE;
                this.UpdateWaybill(waybill);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void VoidWaybill(string billNo, DateTime effDate, User user)
        {
            IList<Waybill> waybillList = this.GetWaybill(billNo);
            foreach (var waybill in waybillList)
            {
                if (waybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CLOSE)
                {
                    throw new BusinessErrorException("TMS.Waybill.Error.StatusErrorWhenVoid", waybill.Status, waybill.WaybillNo);
                }
                waybill.VoidDate = effDate;
                waybill.VoidUser = user.Code;
                waybill.VoidUserNm = user.Name;
                waybill.LastModifyDate = effDate;
                waybill.LastModifyUser = user.Code;
                waybill.LastModifyUserNm = user.Name;
                waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_COMPLETE;
                this.UpdateWaybill(waybill);
            }
        }
        /// <summary>
        /// 适用于关闭ASN时同步关闭运单
        /// </summary>
        /// <param name="ipNo"></param>
        /// <param name="user"></param>
        [Transaction(TransactionMode.Requires)]
        public void CompleteWaybill(string ipNo, User user)
        {
            //验证ASN是否都关闭
            SqlParameter[] sqlParam = new SqlParameter[1];
            sqlParam[0] = new SqlParameter("@IpNo", ipNo);
            DataSet completeWaybillDS = this.sqlHelperMgr.GetDatasetByStoredProcedure("USP_Search_CompleteWaybill", sqlParam);
            IList<Waybill> completeWaybillList =
                IListHelper.DataTableToList<Waybill>(completeWaybillDS.Tables[0]);
            if (completeWaybillList == null || completeWaybillList.Count == 0)
            {
                return;
            }
            foreach (var waybill in completeWaybillList)
            {
                //var waybill = this.CheckAndLoadWaybill(waybillNo);
                if (waybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_INPROCESS)
                {
                    //throw new BusinessErrorException("TMS.Waybill.Error.StatusErrorWhenComplete", waybill.Status, waybill.WaybillNo);
                    continue;
                }
                waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_COMPLETE;

                DateTime now = DateTime.Now;
                waybill.IsAutoComplete = true;
                waybill.CompleteDate = now;
                waybill.CompleteUser = user.Code;
                waybill.CompleteUserNm = user.Name;
                waybill.LastModifyDate = now;
                waybill.LastModifyUser = user.Code;
                waybill.LastModifyUserNm = user.Name;

                this.UpdateWaybill(waybill);

                this.actbillMgrE.CreateTActBill(waybill, user);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void CompleteWaybill(string waybillNo, string freightNo, string settleTime, string remark, User user)
        {
            var waybill = this.CheckAndLoadWaybill(waybillNo);
            if (waybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_INPROCESS)
            {
                throw new BusinessErrorException("TMS.Waybill.Error.StatusErrorWhenComplete", waybill.Status, waybill.WaybillNo);
            }
            waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_COMPLETE;

            if (!string.IsNullOrEmpty(settleTime))
            {
                waybill.SettleTime = DateTime.Parse(settleTime);
            }
            else
            {
                waybill.SettleTime = null;
            }
            DateTime now = DateTime.Now;
            waybill.CompleteDate = now;
            waybill.CompleteUser = user.Code;
            waybill.CompleteUserNm = user.Name;
            waybill.LastModifyDate = now;
            waybill.LastModifyUser = user.Code;
            waybill.LastModifyUserNm = user.Name;
            waybill.Remark = remark;

            this.UpdateFreight(waybill, waybill.FreightNo, freightNo, now, user.Code, user.Name);

            this.UpdateWaybill(waybill);

            this.actbillMgrE.CreateTActBill(waybill, user);
        }

        /// <summary>
        /// 使用零星运输
        /// </summary>
        /// <param name="waybillNo"></param>
        /// <param name="freightNo"></param>
        /// <param name="isFree"></param>
        /// <param name="settleTime"></param>
        /// <param name="remark"></param>
        /// <param name="user"></param>
        [Transaction(TransactionMode.Requires)]
        public void CompleteWaybill(string waybillNo, string freightNo, bool isFree, string settleTime, string remark, User user)
        {
            var waybill = this.CheckAndLoadWaybill(waybillNo);
            if (waybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_INPROCESS)
            {
                throw new BusinessErrorException("TMS.Waybill.Error.StatusErrorWhenComplete", waybill.Status, waybill.WaybillNo);
            }
            waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_COMPLETE;
            waybill.IsFree = isFree;
            if (!string.IsNullOrEmpty(settleTime))
            {
                waybill.SettleTime = DateTime.Parse(settleTime);
            }
            else
            {
                waybill.SettleTime = null;
            }
            DateTime now = DateTime.Now;
            waybill.CompleteDate = now;
            waybill.CompleteUser = user.Code;
            waybill.CompleteUserNm = user.Name;
            waybill.LastModifyDate = now;
            waybill.LastModifyUser = user.Code;
            waybill.LastModifyUserNm = user.Name;
            waybill.Remark = remark;

            this.UpdateFreight(waybill, waybill.FreightNo, freightNo, now, user.Code, user.Name);

            this.UpdateWaybill(waybill);

            actbillMgrE.CreateTActBill(waybill, user);
        }

        [Transaction(TransactionMode.Requires)]
        public void SubmitWaybill(Waybill waybill, User user)
        {
            Waybill oldWaybill = this.CheckAndLoadWaybill(waybill.WaybillNo);
            if (oldWaybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE)
            {
                throw new BusinessErrorException("TMS.Waybill.Error.StatusErrorWhenSubmit", waybill.Status, waybill.WaybillNo);
            }

            var waybillDetList = this.waybillDetMgrE.GetWaybillDet(waybill.WaybillNo);
            if (oldWaybill.Type != TMSConstants.CODE_MASTER_TMS_TYPE_RST && oldWaybill.IsASN && (waybillDetList == null || waybillDetList.Count == 0))
            {
                throw new BusinessErrorException("TMS.Waybill.NoWaybillDet");
            }

            DateTime now = DateTime.Now;
            oldWaybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_SUBMIT;
            oldWaybill.SubmitDate = now;
            oldWaybill.SubmitUser = user.Code;
            oldWaybill.SubmitUserNm = user.Name;
            oldWaybill.LastModifyDate = now;
            oldWaybill.LastModifyUser = user.Code;
            oldWaybill.LastModifyUserNm = user.Name;

            GetTonnageVolume(oldWaybill, oldWaybill.TonnageVolume, oldWaybill.Tonnage, waybill.Tonnage);

            if (oldWaybill.Type == TMSConstants.CODE_MASTER_TMS_TYPE_RST)
            {
                oldWaybill.IsFree = waybill.IsFree;
            }

            //更改承运商
            UpdateCarier(waybill, oldWaybill);

            CloneHelper.CopyProperty(waybill, oldWaybill, Waybill2WaybillCloneFields);

            UpdateDriver(oldWaybill, oldWaybill.Driver, waybill.Driver);

            UpdateVehicle(oldWaybill, oldWaybill.Vehicle, waybill.Vehicle);

            this.UpdateFreight(oldWaybill, oldWaybill.FreightNo, waybill.FreightNo, now, user.Code, user.Name);

            this.UpdateAuto(oldWaybill, now, user);

            this.UpdateWaybill(oldWaybill);
        }

        private void UpdateAuto(Waybill waybill, DateTime effDate, User user)
        {
            if (string.IsNullOrEmpty(waybill.Status))
            {
                waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE;
                waybill.CreateDate = effDate;
                waybill.CreateUser = user.Code;
                waybill.CreateUserNm = user.Name;
            }
            if (waybill.Status == TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE)
            {
                if (waybill.IsAutoRelease)
                {
                    waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_SUBMIT;
                    waybill.SubmitDate = effDate;
                    waybill.SubmitUser = user.Code;
                    waybill.SubmitUserNm = user.Name;
                }
            }
            if (waybill.Status == TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_SUBMIT)
            {
                if (waybill.IsAutoStart)
                {
                    waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_INPROCESS;
                    waybill.StartDate = effDate;
                    waybill.StartUser = user.Code;
                    waybill.StartUserNm = user.Name;
                }
            }/*
            if (waybill.Status == TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_INPROCESS)
            {
                if (waybill.IsAutoComplete)
                {
                    waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_COMPLETE;
                    waybill.CompleteDate = effDate;
                    waybill.CompleteUser = user.Code;
                    waybill.CompleteUserNm = user.Name;
                }
            }*/
        }

        private void UpdateKM(Waybill waybill, DateTime effDate, string userCode, string userName)
        {
            if (waybill.IsMorePlace && (waybill.Status == TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE || waybill.Status == TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_SUBMIT))
            {
                //里程计价才计算公里数
                if (waybill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_BUS_KM)
                {
                    IList<string> placeList = TMSUtil.GetPlaceList(waybill.ShipFrom, waybill.ShipTo, waybill.MorePlace);
                    IList<PlaceDet> placeDetList = this.placeDetMgrE.GetPlaceDetList(waybill.WaybillNo, placeList, effDate, userCode, userName);
                    if (placeDetList != null && placeDetList.Count > 0)
                    {
                        StringBuilder morePlace = new StringBuilder();
                        foreach (var placeDet in placeDetList)
                        {
                            if (waybill.Status == TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_SUBMIT)
                            {
                                if (morePlace.Length == 0)
                                {
                                    morePlace.Append(placeDet.ShipFromName);
                                }

                                morePlace.Append(" - ");
                                morePlace.Append(placeDet.ShipToName);
                                morePlace.Append("(");
                                morePlace.Append(placeDet.Km.ToString("0.########"));
                                morePlace.Append(")");

                                waybill.MorePlace = morePlace.ToString();

                                var oldPlaceDet = placeDetMgrE.LoadPlaceDet(waybill.WaybillNo, placeDet.ShipFrom, placeDet.ShipTo, false);
                                if (oldPlaceDet != null)
                                {
                                    oldPlaceDet.Km = placeDet.Km;
                                    oldPlaceDet.ShipFromDesc = placeDet.ShipFromDesc;
                                    oldPlaceDet.ShipToDesc = placeDet.ShipToDesc;
                                    oldPlaceDet.Remark = placeDet.Remark;
                                    oldPlaceDet.Seq = placeDet.Seq;
                                    oldPlaceDet.LastModifyDate = placeDet.LastModifyDate;
                                    oldPlaceDet.LastModifyUser = placeDet.LastModifyUser;
                                    oldPlaceDet.LastModifyUserNm = placeDet.LastModifyUserNm;
                                    placeDetMgrE.UpdatePlaceDet(oldPlaceDet);
                                }
                            }
                            else
                            {
                                this.placeDetMgrE.CreatePlaceDet(placeDet);
                            }
                        }
                        //里程
                        waybill.Km = placeDetList.Sum(p => p.Km);
                    }
                }
            }
        }

        /// <summary>
        /// 根据吨位更新体积
        /// </summary>
        /// <param name="waybill"></param>
        /// <param name="oldWaybill"></param>
        private void GetTonnageVolume(Waybill waybill, decimal? tonnageVolume, string srcTonnage, string targetTonnage)
        {
            if (srcTonnage != targetTonnage)
            {
                Tonnage tonnage = this.tonnageMgrE.LoadTonnage(targetTonnage);
                waybill.TonnageVolume = tonnage.Volume;
                waybill.TonnageWeight = tonnage.Weight;
            }
            //return tonnageVolume;
        }

        [Transaction(TransactionMode.Requires)]
        public void UpdateWaybill(Waybill waybill, User user)
        {
            Waybill oldWaybill = this.CheckAndLoadWaybill(waybill.WaybillNo);

            GetTonnageVolume(oldWaybill, oldWaybill.TonnageVolume, oldWaybill.Tonnage, waybill.Tonnage);

            if (oldWaybill.Type == TMSConstants.CODE_MASTER_TMS_TYPE_RST)
            {
                oldWaybill.IsFree = waybill.IsFree;
            }

            //更改承运商
            UpdateCarier(waybill, oldWaybill);

            CloneHelper.CopyProperty(waybill, oldWaybill, Waybill2WaybillCloneFields);

            DateTime now = DateTime.Now;
            oldWaybill.LastModifyDate = now;
            oldWaybill.LastModifyUser = user.Code;
            oldWaybill.LastModifyUserNm = user.Name;

            this.UpdateDriver(oldWaybill, oldWaybill.Driver, waybill.Driver);

            this.UpdateVehicle(oldWaybill, oldWaybill.Vehicle, waybill.Vehicle);

            this.UpdateFreight(oldWaybill, oldWaybill.FreightNo, waybill.FreightNo, now, user.Code, user.Name);

            this.UpdateWaybill(oldWaybill);
        }

        private void UpdateCarier(Waybill waybill, Waybill oldWaybill)
        {
            if (waybill.Carrier != oldWaybill.Carrier)
            {
                Carrier carrier = this.carrierMgrE.LoadCarrier(waybill.Carrier);
                oldWaybill.Carrier = waybill.Carrier;
                oldWaybill.CarrierDesc = carrier.Name;

                UpdateFlowDet(oldWaybill);
            }
        }

        private void UpdateFlowDet(Waybill waybill)
        {
            if (!string.IsNullOrEmpty(waybill.Flow))
            {
                IList<TFlowDet> flowDetList = flowDetMgrE.GetActiveTFlowDets(waybill.Flow, waybill.Carrier, waybill.Tonnage);
                if (flowDetList != null && flowDetList.Count > 0)
                {
                    //todo 优化选择路线明细计费

                    CloneHelper.CopyProperty(flowDetList[0], waybill, TMSUtil.FlowDet2WaybillCloneFields);
                    waybill.FlowDet = flowDetList[0].Id;
                    waybill.FlowCurrency = waybill.Currency;
                    waybill.IsFree = string.IsNullOrEmpty(waybill.PricingMethod);
                }
                else
                {
                    waybill.IsFree = false;
                    waybill.IsProvEst = true;
                    waybill.Freight = 0;
                    waybill.PricingMethod = string.Empty;
                    waybill.PriceList = string.Empty;
                    waybill.BillAddr = string.Empty;
                    waybill.Currency = string.Empty;
                    waybill.FlowCurrency = string.Empty;
                    waybill.RoundUpOpt = 0;
                    waybill.UnitPrice = 0;
                    waybill.InOutFee = 0;
                    waybill.SendFee = 0;
                    waybill.ServiceFee = 0;
                }
            }
        }

        /// <summary>
        /// 适用RST
        /// </summary>
        /// <param name="waybill"></param>
        [Transaction(TransactionMode.Requires)]
        public override void CreateWaybill(Waybill waybill)
        {
            if (waybill.IsAutoRelease)
            {
                waybill.SubmitDate = waybill.LastModifyDate;
                waybill.SubmitUser = waybill.LastModifyUser;
                waybill.SubmitUserNm = waybill.LastModifyUserNm;
                waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_SUBMIT;
            }
            else
            {
                waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE;
            }

            waybill.WaybillNo = numberControlMgrE.GenerateNumber(waybill.Type);

            GetTonnageVolume(waybill, waybill.TonnageVolume, string.Empty, waybill.Tonnage);

            this.UpdateDriver(waybill, string.Empty, waybill.Driver);

            this.UpdateVehicle(waybill, string.Empty, waybill.Vehicle);

            this.UpdateFreight(waybill, string.Empty, waybill.FreightNo, waybill.LastModifyDate, waybill.LastModifyUser, waybill.LastModifyUserNm);

            User user = new User();
            user.Code = waybill.LastModifyUser;
            user.FirstName = waybill.LastModifyUserNm;

            this.UpdateAuto(waybill, waybill.LastModifyDate, user);

            base.CreateWaybill(waybill);

        }

        /// <summary>
        /// 适用于常规运单和后续运单
        /// </summary>
        /// <param name="waybill"></param>
        /// <param name="WaybillDetList"></param>
        /// <param name="user"></param>
        [Transaction(TransactionMode.Requires)]
        public void CreateWaybill(Waybill waybill, IList<WaybillDet> WaybillDetList, User user)
        {
            //waybill.WaybillNo = numberControlMgrE.GenerateNumber(TMSConstants.CODE_MASTER_TMS_TYPE_COM);
            waybill.WaybillNo = numberControlMgrE.GenerateNumber(waybill.Type);

            GetTonnageVolume(waybill, waybill.TonnageVolume, string.Empty, waybill.Tonnage);

            if (!string.IsNullOrEmpty(waybill.Flow))
            {
                TFlow flow = flowMgrE.LoadTFlow(waybill.Flow);
                CloneHelper.CopyProperty(flow, waybill, Flow2WaybillCloneFields);
                waybill.FlowDesc = flow.Desc;
            }

            DateTime now = DateTime.Now;
            waybill.CreateDate = now;
            waybill.CreateUser = user.Code;
            waybill.CreateUserNm = user.Name;
            waybill.LastModifyDate = now;
            waybill.LastModifyUser = user.Code;
            waybill.LastModifyUserNm = user.Name;

            Carrier carrier = this.carrierMgrE.LoadCarrier(waybill.Carrier);
            waybill.CarrierDesc = carrier.Name;

            if (waybill.IsAutoRelease)
            {
                if (waybill.IsASN)
                {
                    if (WaybillDetList == null || WaybillDetList.Count == 0)
                    {
                        throw new BusinessErrorException("TMS.Waybill.NoWaybillDet");
                    }
                }

                waybill.SubmitDate = now;
                waybill.SubmitUser = user.Code;
                waybill.SubmitUserNm = user.Name;
                waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_SUBMIT;
            }
            else
            {
                waybill.Status = TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE;
            }

            this.UpdateFlowDet(waybill);

            this.UpdateDriver(waybill, string.Empty, waybill.Driver);

            this.UpdateVehicle(waybill, string.Empty, waybill.Vehicle);

            base.CreateWaybill(waybill);

            //this.UpdateKM(waybill, now, waybill.LastModifyUser, waybill.LastModifyUserNm);
            this.UpdateFreight(waybill, string.Empty, waybill.FreightNo, now, waybill.LastModifyUser, waybill.LastModifyUserNm);

            this.UpdateAuto(waybill, now, user);

            UpdateWaybill(waybill);

            //更新明细
            foreach (WaybillDet waybillDet in WaybillDetList)
            {
                waybillDet.WaybillNo = waybill.WaybillNo;

                this.waybillDetMgrE.CreateWaybillDet(waybillDet);

                InProcessLocation ip = ipDao.LoadInProcessLocation(waybillDet.IpNo);
                ip.WaybillNo = waybillDet.WaybillNo;
                ipDao.UpdateInProcessLocation(ip);
            }
        }

        [Transaction(TransactionMode.Requires)]
        protected void UpdateVehicle(Waybill waybill, string srcVehicle, string targetVehicle)
        {
            if (string.IsNullOrEmpty(srcVehicle)) srcVehicle = string.Empty;
            if (string.IsNullOrEmpty(targetVehicle)) targetVehicle = string.Empty;
            if (srcVehicle != targetVehicle)
            {
                Vehicle vehicle = this.vehicleMgrE.LoadVehicle(targetVehicle);
                if (vehicle == null)
                {
                    waybill.Vehicle = targetVehicle;
                    waybill.AuthVehicle = false;
                }
                else
                {
                    waybill.Vehicle = vehicle.Code;
                    waybill.AuthVehicle = true;
                }
            }
        }

        [Transaction(TransactionMode.Requires)]
        protected void UpdateDriver(Waybill waybill, string srcDriver, string targetDriver)
        {
            if (string.IsNullOrEmpty(srcDriver)) srcDriver = string.Empty;
            if (string.IsNullOrEmpty(targetDriver)) targetDriver = string.Empty;
            if (srcDriver != targetDriver)
            {
                if (string.IsNullOrEmpty(targetDriver))
                {
                    waybill.Driver = targetDriver;
                    waybill.AuthDriver = false;
                    waybill.DriverDesc = string.Empty;
                }
                else
                {
                    Driver driver = this.driverMgrE.LoadDriver(targetDriver);
                    if (driver == null)
                    {
                        waybill.Driver = targetDriver;
                        waybill.AuthDriver = false;
                        waybill.DriverDesc = string.Empty;
                    }
                    else
                    {
                        waybill.Driver = driver.Code;
                        waybill.AuthDriver = true;
                        waybill.DriverDesc = driver.Name;
                    }
                }
            }
        }

        [Transaction(TransactionMode.Requires)]
        protected void UpdateFreight(Waybill waybill, string srcFreightNo, string targetFreightNo, DateTime effDate, string userCode, string userName)
        {
            UpdateKM(waybill, effDate, userCode, userName);

            UpdateFreight(waybill, srcFreightNo, targetFreightNo, userCode, userName);
        }
        protected void UpdateFreight(Waybill waybill, string srcFreightNo, string targetFreightNo, string userCode, string userName)
        {
            if (string.IsNullOrEmpty(srcFreightNo)) srcFreightNo = string.Empty;
            if (string.IsNullOrEmpty(targetFreightNo)) targetFreightNo = string.Empty;
            if (srcFreightNo != targetFreightNo)
            {
                if (string.IsNullOrEmpty(targetFreightNo))
                {
                    waybill.FreightNo = string.Empty;
                    waybill.Currency = waybill.FlowCurrency;
                    waybill.Freight = 0;
                }
                else
                {
                    var targetFreight = freightMgrE.LoadFreight(targetFreightNo);
                    if (targetFreight != null && targetFreight.Status == TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_SUBMIT)
                    {
                        waybill.IsFree = false;
                        waybill.FreightNo = targetFreightNo;
                        waybill.Currency = targetFreight.Currency;
                        waybill.Freight = targetFreight.Freight;
                        waybill.BillAddr = targetFreight.BillAddr;
                        freightMgrE.CloseFreight(targetFreight, waybill.WaybillNo, waybill.LastModifyUser, waybill.LastModifyUserNm);
                    }
                    else
                    {
                        throw new BusinessErrorException("TMS.Waybill.FreightOcuppied", waybill.FreightNo);
                    }
                }
                if (!string.IsNullOrEmpty(srcFreightNo))
                {
                    this.freightMgrE.OpenFreight(waybill.FreightNo, userCode, userName);
                }
            }
            this.Calculate(waybill, userCode, userName);
        }

        private void Calculate(Waybill waybill, string userCode, string userName)
        {
            if (waybill.IsFree)
            {
                waybill.IsProvEst = false;
            }
            else if (String.IsNullOrEmpty(waybill.FreightNo) && String.IsNullOrEmpty(waybill.PriceList))
            {
                waybill.IsProvEst = true;
            }
            else if (String.IsNullOrEmpty(waybill.FreightNo) && !string.IsNullOrEmpty(waybill.PriceList)
                                && (waybill.Status == TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_SUBMIT || waybill.IsProvEst)
                                && !string.IsNullOrEmpty(waybill.PricingMethod)
                                && waybill.Type != TMSConstants.CODE_MASTER_TMS_TYPE_RST)
            {
                DateTime now = DateTime.Now;

                //常规运输和后续运输
                TPriceListDet priceListDet = this.priceListDetMgrE.LoadTPriceListDet(waybill.PriceList, waybill.PricingMethod, waybill.FlowCurrency, waybill.Tonnage, waybill.ShipFrom, waybill.ShipTo, waybill.Qty, now);
                if (priceListDet == null)
                {
                    waybill.IsProvEst = true;
                    waybill.Freight = 0;
                }
                else
                {
                    CloneHelper.CopyProperty(priceListDet, waybill, TMSUtil.PriceListDet2WaybillCloneFields);
                    decimal amount = 0;
                    //包车
                    if (waybill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_BUS)
                    {
                        amount = priceListDet.UnitPrice + priceListDet.Fee;
                    }
                    else if (waybill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_BUS_KM     //包车里程
                                    || waybill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_STERE    //体积(立方米)
                                    || waybill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_PALLET   //托盘
                                    || waybill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_UNITPACK //箱
                                    || waybill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_LADDERSTERE  //阶梯
                                    || waybill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_KG   //重量(公斤)
                                    || waybill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_UOM  //单位
                                 )
                    {
                        amount = priceListDet.UnitPrice * waybill.Qty + priceListDet.Fee;
                    }
                    //面积(平方米)todo
                    else if (waybill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_SQM)
                    {
                    }
                    //包月todo
                    else if (waybill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_MONTHLY)
                    {
                    }

                    //最低最高运费
                    if (priceListDet.MinPrice.HasValue && priceListDet.MinPrice.Value != 0 && amount < priceListDet.MinPrice.Value)
                    {
                        amount = priceListDet.MinPrice.Value;
                    }
                    if (priceListDet.MaxPrice.HasValue && priceListDet.MaxPrice.Value != 0 && amount > priceListDet.MaxPrice.Value)
                    {
                        amount = priceListDet.MaxPrice.Value;
                    }
                    waybill.Freight = amount;

                    //圆整
                    if (waybill.Freight.HasValue && waybill.Freight.Value != 0)
                    {
                        if (waybill.RoundUpOpt > 0)
                        {
                            waybill.Freight = Math.Ceiling(waybill.Freight.Value);
                        }
                        else if (waybill.RoundUpOpt < 0)
                        {
                            waybill.Freight = Math.Floor(waybill.Freight.Value);
                        }
                        else
                        {
                            EntityPreference entityPreference = this.entityPreferenceMgrE.LoadEntityPreference(
                                                                            BusinessConstants.ENTITY_PREFERENCE_CODE_AMOUNT_DECIMAL_LENGTH);
                            int amountDecimalLength = int.Parse(entityPreference.Value);
                            waybill.Freight = Math.Round(waybill.Freight.Value, amountDecimalLength, MidpointRounding.AwayFromZero);
                        }
                    }
                }
            }
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<Waybill> GetWaybill(string carrier, string shipFrom, string shipTo)
        {
            DetachedCriteria criteria = DetachedCriteria.For(typeof(Waybill));
            if (!string.IsNullOrEmpty(carrier))
            {
                criteria.Add(Expression.Eq("Carrier", carrier));
            }
            if (!string.IsNullOrEmpty(shipFrom))
            {
                criteria.Add(Expression.Eq("ShipFrom", shipFrom));
            }
            if (!string.IsNullOrEmpty(shipTo))
            {
                criteria.Add(Expression.Eq("ShipTo", shipTo));
            }
            return criteriaMgrE.FindAll<Waybill>(criteria);
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<Waybill> GetWaybill(string carrier, string currency, string shipFrom, string shipTo)
        {
            DetachedCriteria criteria = DetachedCriteria.For(typeof(Waybill));
            if (!string.IsNullOrEmpty(carrier))
            {
                criteria.Add(Expression.Eq("Carrier", carrier));
            }
            if (!string.IsNullOrEmpty(currency))
            {
                criteria.Add(Expression.Or(Expression.Eq("Currency", currency), Expression.Or(Expression.IsNull("Currency"), Expression.Eq("Currency", string.Empty))));
            }
            if (!string.IsNullOrEmpty(shipFrom))
            {
                criteria.Add(Expression.Eq("ShipFrom", shipFrom));
            }
            if (!string.IsNullOrEmpty(shipTo))
            {
                criteria.Add(Expression.Eq("ShipTo", shipTo));
            }
            return criteriaMgrE.FindAll<Waybill>(criteria);
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<Waybill> GetWaybill(string billNo)
        {
            DetachedCriteria criteria = DetachedCriteria.For<TBillDet>();
            criteria.Add(Expression.Eq("BillNo", billNo));
            criteria.SetProjection(Projections.ProjectionList().Add(Projections.GroupProperty("Waybill")));

            return criteriaMgrE.FindAll<Waybill>(criteria);
        }


        [Transaction(TransactionMode.Unspecified)]
        public IList<Waybill> GetFrontWaybillNo(string flow)
        {
            DetachedCriteria flowCriteria = DetachedCriteria.For(typeof(TFlow));
            flowCriteria.Add(Expression.Eq("Code", flow));
            flowCriteria.SetProjection(Projections.ProjectionList().Add(Projections.GroupProperty("ShipFrom")));

            DetachedCriteria criteria = DetachedCriteria.For(typeof(Waybill));
            criteria.Add(Expression.Not(Expression.Eq("Status", TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE)));
            criteria.Add(Expression.Not(Expression.Eq("Status", TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CANCEL)));
            //过滤掉零星运单
            criteria.Add(Expression.Not(Expression.Eq("Type", TMSConstants.CODE_MASTER_TMS_TYPE_RST)));
            criteria.Add(Subqueries.PropertyIn("ShipTo", flowCriteria));

            return criteriaMgrE.FindAll<Waybill>(criteria);
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<Waybill> GetWaybill(string[] ipNos, User user)
        {
            if (ipNos == null || ipNos.Length == 0) return null;
            DetachedCriteria criteria = DetachedCriteria.For(typeof(Waybill));
            var waybillDetCrieteria = TMSUtil.GetWaybillCriteria(ipNos);
            criteria.Add(
                    Subqueries.PropertyIn("WaybillNo", waybillDetCrieteria));
            DetachedCriteria[] carrierCrieteria = TMSUtil.GetCarrierPermissionCriteria(user.Code);
            criteria.Add(
                    Expression.Or(
                        Subqueries.PropertyIn("Carrier", carrierCrieteria[0]),
                            Subqueries.PropertyIn("Carrier", carrierCrieteria[1])));
            criteria.AddOrder(Order.Asc("CreateDate"));
            return criteriaMgrE.FindAll<Waybill>(criteria);
        }

        [Transaction(TransactionMode.Requires)]
        public override void DeleteWaybill(string waybillNo)
        {
            Waybill waybill = this.LoadWaybill(waybillNo);
            if (waybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE)
            {
                throw new BusinessErrorException("TMS.Waybill.Error.StatusErrorWhenModify", waybill.Status, waybill.WaybillNo);
            }
            if (waybill.Type != TMSConstants.CODE_MASTER_TMS_TYPE_RST)
            {
                //删除明细
                IList<WaybillDet> waybillDetList = this.waybillDetMgrE.GetWaybillDet(waybillNo);
                if (waybillDetList != null && waybillDetList.Count > 0)
                {
                    foreach (WaybillDet waybillDet in waybillDetList)
                    {
                        InProcessLocation ip = ipDao.LoadInProcessLocation(waybillDet.IpNo);
                        ip.WaybillNo = string.Empty;
                        ipDao.UpdateInProcessLocation(ip);
                        this.waybillDetMgrE.DeleteWaybillDet(waybillDet);
                    }
                }
            }

            //删除多运输地点数据
            if (waybill.IsMorePlace)
            {
                var placeDets = this.placeDetMgrE.GetPlaceDets(waybill.WaybillNo);
                if (placeDets != null && placeDets.Count > 0)
                {
                    this.placeDetMgrE.DeletePlaceDet(placeDets);
                }
            }
            base.DeleteWaybill(waybill);

            //恢复运费单
            if (!string.IsNullOrEmpty(waybill.FreightNo))
            {
                this.freightMgrE.OpenFreight(waybill.FreightNo, waybill.LastModifyUser, waybill.LastModifyUserNm);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void DeleteWaybillDet(int id, User user)
        {
            WaybillDet waybillDet = this.waybillDetMgrE.LoadWaybillDet(id);
            Waybill waybill = this.LoadWaybill(waybillDet.WaybillNo);
            if (waybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE)
            {
                throw new BusinessErrorException("TMS.Waybill.Error.StatusErrorWhenModify", waybill.Status, waybillDet.WaybillNo);
            }
            else
            {
                waybill.PalletQty -= waybillDet.PalletQty;
                waybill.Volume -= waybillDet.Volume;
                waybill.UnitPack -= waybillDet.UnitPack;
                waybill.LastModifyDate = DateTime.Now;
                waybill.LastModifyUser = user.Code;
                waybill.LastModifyUserNm = user.Name;
                this.UpdateWaybill(waybill);

                InProcessLocation ip = ipDao.LoadInProcessLocation(waybillDet.IpNo);
                ip.WaybillNo = string.Empty;
                ipDao.UpdateInProcessLocation(ip);

                this.waybillDetMgrE.DeleteWaybillDet(id);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void AddWaybillDet(WaybillDet waybillDet, User user)
        {
            Waybill waybill = this.LoadWaybill(waybillDet.WaybillNo);
            if (waybill.Status != TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE)
            {
                throw new BusinessErrorException("TMS.Waybill.Error.StatusErrorWhenModify", TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_CREATE, waybillDet.WaybillNo);
            }
            else
            {
                waybill.PalletQty += waybillDet.PalletQty;
                waybill.Volume += waybillDet.Volume;
                waybill.UnitPack += waybillDet.UnitPack;
                waybill.LastModifyDate = DateTime.Now;
                waybill.LastModifyUser = user.Code;
                waybill.LastModifyUserNm = user.Name;
                this.UpdateWaybill(waybill);

                InProcessLocation ip = ipDao.LoadInProcessLocation(waybillDet.IpNo);
                ip.WaybillNo = waybillDet.WaybillNo;
                ipDao.UpdateInProcessLocation(ip);

                this.waybillDetMgrE.CreateWaybillDet(waybillDet);
            }
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class WaybillMgrE : com.Sconit.TMS.Service.Impl.WaybillMgr, IWaybillMgrE
    {
    }
}

#endregion Extend Class