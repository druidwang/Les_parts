using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.TMS.Persistence;
using com.Sconit.Service;
using com.Sconit.TMS.Entity;
using com.Sconit.TMS.Service.Util;
using com.Sconit.Utility;
using com.Sconit.Entity.MasterData;
using com.Sconit.TMS.Service.Ext;
using NHibernate.Expression;
using com.Sconit.Service.Ext.MasterData;
using com.Sconit.Entity;
using com.Sconit.Service.Ext.Criteria;
using com.Sconit.Entity.Exception;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class TActBillMgr : TActBillBaseMgr, ITActBillMgr
    {
        public IWaybillDao waybillDao { get; set; }
        public IFreightMgrE freightMgrE { get; set; }
        public ICriteriaMgrE criteriaMgrE { get; set; }
        public ITFlowDetMgrE flowDetMgrE { get; set; }
        public IEntityPreferenceMgrE entityPreferenceMgrE { get; set; }
        private string[] Waybill2ActBillCloneFields = new string[] 
            { 
                "Flow",
                "Type",
                "BillAddr",
                "FreightNo",
                "PriceList",
                "Currency",
                "FlowCurrency",
                "IsProvEst",
                "PricingMethod",                
                "Flow",
                "FlowDesc",
                "UnitPrice"
            };

        private string[] FlowDet2ActBillCloneFields = new string[] 
            {                 
                "PricingMethod",
                "PriceList",
                "BillAddr",
                "Currency",
                "RoundUpOpt",
            };

        private string[] PriceListDet2ActBillCloneFields = new string[] 
            {                 
                "UnitPrice",
                "IsProvEst"
            };

        public ITPriceListDetMgrE priceListDetMgrE { get; set; }

        #region Customized Methods
        [Transaction(TransactionMode.Requires)]
        public void CreateTActBill(Waybill waybill, User user)
        {
            if (waybill.Status == TMSConstants.CODE_MASTER_TMS_STATUS_VALUE_COMPLETE && !waybill.IsFree)
            {
                DateTime now = DateTime.Now;
                TActBill actbill = new TActBill();
                CloneHelper.CopyProperty(waybill, actbill, Waybill2ActBillCloneFields);
                actbill.Waybill = waybill;
                actbill.BillAddr = waybill.BillAddr;
                actbill.CreateDate = now;
                actbill.CreateUser = user.Code;
                actbill.CreateUserNm = user.Name;
                actbill.LastModifyDate = now;
                actbill.LastModifyUser = user.Code;
                actbill.LastModifyUserNm = user.Name;
                actbill.EffDate = waybill.SettleTime.HasValue ? waybill.SettleTime.Value : now;
                actbill.BillAmount = waybill.Freight;
                actbill.BilledAmount = 0;
                actbill.BillQty = waybill.Qty;
                actbill.BilledQty = 0;
                if (waybill.Status == TMSConstants.CODE_MASTER_TMS_TYPE_RST || !string.IsNullOrEmpty(waybill.FreightNo))
                {
                    if (string.IsNullOrEmpty(actbill.FreightNo))
                    {
                        actbill.IsProvEst = true;
                    }
                    else
                    {
                        actbill.IsProvEst = false;
                    }
                }

                this.CreateTActBill(actbill);
            }
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<TActBill> GetTActBill(string type, string carrier, string freightNo, DateTime? effDateFrom, DateTime? effDateTo, string waybillNo, string extNo, string currency)
        {
            return GetTActBill(type, carrier, freightNo, effDateFrom, effDateTo, waybillNo, currency, extNo, false);
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<TActBill> GetTActBill(string type, string carrier, DateTime? effDateFrom, DateTime? effDateTo, string waybillNo, string currency, string extNo, string pricingMethod, bool? isProvEst)
        {
            return GetTActBill(type, carrier, string.Empty, effDateFrom, effDateTo, waybillNo, currency, extNo, pricingMethod, isProvEst);
        }
        [Transaction(TransactionMode.Unspecified)]
        public IList<TActBill> GetTActBill(string type, string carrier, string freightNo, DateTime? effDateFrom, DateTime? effDateTo, string waybillNo, string currency, string extNo, bool? isProvEst)
        {
            return this.GetTActBill(type, carrier, freightNo, effDateFrom, effDateTo, waybillNo, currency, extNo, string.Empty, isProvEst);
        }
        [Transaction(TransactionMode.Unspecified)]
        public IList<TActBill> GetTActBill(string type, string carrier, string freightNo, DateTime? effDateFrom, DateTime? effDateTo, string waybillNo, string currency, string extNo, string pricingMethod, bool? isProvEst)
        {
            DetachedCriteria criteria = DetachedCriteria.For<TActBill>();
            criteria.CreateAlias("Waybill", "w");
            if (type != null && type != string.Empty)
            {
                criteria.Add(Expression.Eq("Type", type));
            }
            if (carrier != null && carrier != string.Empty)
            {
                criteria.Add(Expression.Eq("w.Carrier", carrier));
            }
            if (freightNo != null && freightNo != string.Empty)
            {
                criteria.Add(Expression.Like("FreightNo", freightNo, MatchMode.Start));
            }
            if (!string.IsNullOrEmpty(pricingMethod))
            {
                criteria.Add(Expression.Eq("PricingMethod", pricingMethod));
            }
            if (extNo != null && extNo != string.Empty)
            {
                criteria.Add(Expression.Like("ExtNo", extNo, MatchMode.Start));
            }

            if (effDateFrom.HasValue)
            {
                criteria.Add(Expression.Ge("EffDate", effDateFrom.Value));
            }

            if (effDateTo.HasValue)
            {
                criteria.Add(Expression.Le("EffDate", effDateTo.Value));
            }

            if (waybillNo != null && waybillNo != string.Empty)
            {
                criteria.Add(Expression.Eq("w.WaybillNo", waybillNo));
            }
            if (currency != null && currency != string.Empty)
            {
                criteria.Add(Expression.Eq("Currency", currency));
            }
            criteria.Add(Expression.Eq("IsBilled", false));

            if (isProvEst.HasValue)
            {
                criteria.Add(Expression.Eq("IsProvEst", isProvEst));   //非暂估价
            }

            return this.criteriaMgrE.FindAll<TActBill>(criteria);
        }

        [Transaction(TransactionMode.Requires)]
        public void UpdateBilled(int id, User user)
        {
            var actBill = this.LoadTActBill(id);
            this.UpdateBilled(actBill, null, user);
        }

        [Transaction(TransactionMode.Requires)]
        public void UpdateBilled(TActBill actBill, User user)
        {
            this.UpdateBilled(actBill, null, user);
        }

        [Transaction(TransactionMode.Requires)]
        public void UpdateBilled(TActBill actBill, TBillDet billDetail, User user)
        {
            actBill.IsBilled = !actBill.IsBilled;
            if (!actBill.IsBilled)
            {
                actBill.BilledAmount = null;
                actBill.BilledQty = 0;
            }
            else if (billDetail != null)
            {
                actBill.BilledAmount = billDetail.BilledAmount;
            }
            actBill.LastModifyDate = DateTime.Now;
            actBill.LastModifyUser = user.Code;
            actBill.LastModifyUserNm = user.Name;

            this.UpdateTActBill(actBill);
        }

        [Transaction(TransactionMode.Requires)]
        public void RecalculatePrice(IList<TActBill> actingBillList, User user)
        {
            if (actingBillList != null && actingBillList.Count > 0)
            {
                DateTime dateTimeNow = DateTime.Now;

                foreach (TActBill actbill in actingBillList)
                {
                    Waybill waybill = actbill.Waybill;
                    if (!string.IsNullOrEmpty(actbill.FreightNo))
                    {
                        var targetFreight = freightMgrE.CheckAndLoadFreight(actbill.FreightNo);
                        if (targetFreight != null && targetFreight.Status == TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_SUBMIT)
                        {
                            actbill.IsProvEst = false;
                            actbill.Currency = targetFreight.Currency;
                            actbill.BillAmount = targetFreight.Freight;
                            actbill.BilledAmount = 0;
                            actbill.BilledQty = 0;
                            actbill.BillQty = 1;
                            actbill.BillAddr = targetFreight.BillAddr;
                            freightMgrE.CloseFreight(targetFreight, waybill.WaybillNo, user.Code, user.Name);
                            waybill.Freight = targetFreight.Freight;
                            waybill.Currency = targetFreight.Currency;
                            waybill.FreightNo = targetFreight.FreightNo;
                        }
                        else
                        {
                            throw new BusinessErrorException("TMS.Waybill.FreightOcuppied", actbill.FreightNo);
                        }
                    }
                    else
                    {
                        DateTime now = DateTime.Now;
                        //重新读取路线明细的配置，以免之前配置错误
                        //if (string.IsNullOrEmpty(actbill.PriceList))
                        //{
                        IList<TFlowDet> flowDetList = flowDetMgrE.GetActiveTFlowDets(actbill.Flow, waybill.Carrier, waybill.Tonnage);
                        if (flowDetList != null && flowDetList.Count > 0)
                        {
                            CloneHelper.CopyProperty(flowDetList[0], actbill, FlowDet2ActBillCloneFields);
                            actbill.FlowCurrency = actbill.Currency;
                            CloneHelper.CopyProperty(flowDetList[0], waybill, TMSUtil.FlowDet2WaybillCloneFields);
                        }
                        //}
                        if (!string.IsNullOrEmpty(actbill.PriceList))
                        {
                            if (string.IsNullOrEmpty(actbill.PricingMethod))
                            {
                                actbill.BillAmount = 0;
                                actbill.IsProvEst = false;
                                waybill.IsProvEst = false;
                            }
                            else
                            {
                                TPriceListDet priceListDet = this.priceListDetMgrE.LoadTPriceListDet(actbill.PriceList, actbill.PricingMethod, actbill.FlowCurrency, actbill.Waybill.Tonnage, actbill.Waybill.ShipFrom, actbill.Waybill.ShipTo, actbill.BillQty, now);

                                if (priceListDet != null)
                                {
                                    CloneHelper.CopyProperty(priceListDet, actbill, PriceListDet2ActBillCloneFields);
                                    CloneHelper.CopyProperty(priceListDet, waybill, TMSUtil.PriceListDet2WaybillCloneFields);
                                    actbill.BillQty = waybill.Qty;

                                    decimal amount = 0;
                                    //包车
                                    if (actbill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_BUS)
                                    {
                                        amount = priceListDet.UnitPrice + priceListDet.Fee;
                                    }
                                    else if (actbill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_BUS_KM     //包车里程
                                                || actbill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_STERE    //体积(立方米)
                                                || actbill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_PALLET   //托盘
                                                || actbill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_UNITPACK //箱
                                                || actbill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_LADDERSTERE  //阶梯
                                                || actbill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_KG   //重量(公斤)
                                                || actbill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_UOM  //单位
                                                )
                                    {
                                        amount = priceListDet.UnitPrice * actbill.BillQty + priceListDet.Fee;
                                    }
                                    //面积(平方米)todo
                                    else if (actbill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_SQM)
                                    {

                                    }
                                    //包月todo
                                    else if (actbill.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_MONTHLY)
                                    {

                                    }

                                    //最低最高价
                                    if (priceListDet.MinPrice.HasValue && priceListDet.MinPrice.Value != 0 && amount < priceListDet.MinPrice.Value)
                                    {
                                        amount = priceListDet.MinPrice.Value;
                                    }
                                    if (priceListDet.MaxPrice.HasValue && priceListDet.MaxPrice.Value != 0 && amount > priceListDet.MaxPrice.Value)
                                    {
                                        amount = priceListDet.MaxPrice.Value;
                                    }

                                    actbill.BillAmount = amount;

                                    if (actbill.BillAmount.HasValue && actbill.BillAmount.Value != 0)
                                    {
                                        if (actbill.RoundUpOpt > 0)
                                        {
                                            actbill.BillAmount = Math.Ceiling(actbill.BillAmount.Value);
                                        }
                                        else if (actbill.RoundUpOpt < 0)
                                        {
                                            actbill.BillAmount = Math.Floor(actbill.BillAmount.Value);
                                        }
                                        else
                                        {
                                            EntityPreference entityPreference = this.entityPreferenceMgrE.LoadEntityPreference(
                                                                                            BusinessConstants.ENTITY_PREFERENCE_CODE_AMOUNT_DECIMAL_LENGTH);
                                            int amountDecimalLength = int.Parse(entityPreference.Value);
                                            actbill.BillAmount = Math.Round(actbill.BillAmount.Value, amountDecimalLength, MidpointRounding.AwayFromZero);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    waybill.LastModifyDate = dateTimeNow;
                    waybill.LastModifyUser = user.Code;
                    waybill.LastModifyUserNm = user.Name;
                    this.waybillDao.UpdateWaybill(waybill);

                    actbill.LastModifyDate = dateTimeNow;
                    actbill.LastModifyUser = user.Code;
                    actbill.LastModifyUserNm = user.Name;
                    this.UpdateTActBill(actbill);
                }
            }
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class TActBillMgrE : com.Sconit.TMS.Service.Impl.TActBillMgr, ITActBillMgrE
    {
    }
}

#endregion Extend Class