using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.TMS.Persistence;
using com.Sconit.Service;
using com.Sconit.Entity.MasterData;
using com.Sconit.TMS.Service.Util;
using com.Sconit.Entity.Exception;
using com.Sconit.TMS.Entity;
using com.Sconit.TMS.Service.Ext;
using com.Sconit.Service.Ext.MasterData;
using System.Linq;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class TBillMgr : TBillBaseMgr, ITBillMgr
    {
        public INumberControlMgrE numberControlMgrE { get; set; }
        public ITActBillMgrE actBillMgrE { get; set; }
        public ITBillDetMgrE billDetMgrE { get; set; }
        public IWaybillMgrE waybillMgrE { get; set; }
        #region Customized Methods

        [Transaction(TransactionMode.Unspecified)]
        public TBill CheckAndLoadTBill(string billNo)
        {
            TBill bill = this.LoadTBill(billNo);
            if (bill != null)
            {
                return bill;
            }
            else
            {
                throw new BusinessErrorException("TMS.Bill.Error.BillNoNotExist", billNo);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void DeleteTBill(string billNo, User user)
        {
            TBill oldTBill = this.CheckAndLoadTBill(billNo);

            #region 检查状态
            if (oldTBill.Status != TMSConstants.CODE_MASTER_TMS_BILLSTATUS_CREATE)
            {
                throw new BusinessErrorException("TMS.Bill.Error.StatusErrorWhenDelete", oldTBill.Status, oldTBill.BillNo);
            }
            #endregion
            IList<TBillDet> billDetList = this.billDetMgrE.GetTBillDet(oldTBill.BillNo);
            if (billDetList != null && billDetList.Count > 0)
            {
                foreach (TBillDet billDet in billDetList)
                {
                    actBillMgrE.UpdateBilled(billDet.ActBill, user);
                    this.billDetMgrE.DeleteTBillDet(billDet);
                }
            }

            this.DeleteTBill(oldTBill);
        }

        [Transaction(TransactionMode.Requires)]
        public IList<TBill> CreateTBill(IList<TActBill> actBillList, bool isRelease, User user)
        {
            if (isRelease)
            {
                return this.CreateTBill(actBillList, user, TMSConstants.CODE_MASTER_TMS_BILLSTATUS_SUBMIT, 0);
            }
            else
            {
                return this.CreateTBill(actBillList, user, TMSConstants.CODE_MASTER_TMS_BILLSTATUS_CREATE, 0);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public IList<TBill> CreateTBill(IList<TActBill> actBillList, User user, string status, decimal discount)
        {
            if (status != TMSConstants.CODE_MASTER_TMS_BILLSTATUS_CREATE
                && status != TMSConstants.CODE_MASTER_TMS_BILLSTATUS_SUBMIT)
            {
                throw new TechnicalException("status specified is not valided");
            }

            if (actBillList == null || actBillList.Count == 0)
            {
                throw new BusinessErrorException("TMS.Bill.Error.EmptyBillDetails");
            }

            DateTime dateTimeNow = DateTime.Now;
            IList<TBill> billList = new List<TBill>();

            foreach (TActBill actBill in actBillList)
            {
                TActBill oldTActBill = this.actBillMgrE.LoadTActBill(actBill.Id);
                oldTActBill.BilledAmount = actBill.BilledAmount;

                TBill bill = null;

                #region 查找和待开明细的billAddress、currency一致的TBillMstr
                foreach (TBill thisTBill in billList)
                {
                    if (thisTBill.BillAddr == oldTActBill.BillAddr
                        && thisTBill.Currency == oldTActBill.Currency)
                    {
                        bill = thisTBill;
                        break;
                    }
                }
                #endregion

                #region 没有找到匹配的TBill，新建
                if (bill == null)
                {
                    #region 检查权限
                    bool hasPermission = false;
                    foreach (Permission permission in user.OrganizationPermission)
                    {
                        if (permission.Code == oldTActBill.Waybill.Carrier)
                        {
                            hasPermission = true;
                            break;
                        }
                    }

                    if (!hasPermission)
                    {
                        throw new BusinessErrorException("TMS.Bill.Create.Error.NoAuthrization", oldTActBill.Waybill.Carrier);
                    }
                    #endregion

                    #region 创建TBill
                    bill = new TBill();
                    bill.BillNo = numberControlMgrE.GenerateNumber(TMSConstants.CODE_PREFIX_TMS_BILL);
                    bill.Status = status;
                    bill.BillAddr = oldTActBill.BillAddr;
                    bill.Carrier = oldTActBill.Waybill.Carrier;
                    bill.CarrierDesc = oldTActBill.Waybill.CarrierDesc;
                    bill.Currency = oldTActBill.Currency;
                    bill.Discount = discount;
                    bill.CreateDate = dateTimeNow;
                    bill.CreateUser = user.Code;
                    bill.CreateUserNm = user.Name;
                    if (status == TMSConstants.CODE_MASTER_TMS_BILLSTATUS_SUBMIT)
                    {
                        bill.SubmitDate = dateTimeNow;
                        bill.SubmitUser = user.Code;
                        bill.SubmitUserNm = user.Name;
                    }
                    bill.LastModifyDate = dateTimeNow;
                    bill.LastModifyUser = user.Code;
                    bill.LastModifyUserNm = user.Name;
                    this.CreateTBill(bill);
                    billList.Add(bill);
                    #endregion
                }
                #endregion

                if ((oldTActBill.BillAmount.HasValue && oldTActBill.BillAmount.Value != 0)
                        || (oldTActBill.BilledAmount.HasValue && oldTActBill.BilledAmount.Value != 0))
                {
                    bill.BillAmount += oldTActBill.BillAmount.HasValue ? oldTActBill.BillAmount.Value : 0;
                    bill.BilledAmount += oldTActBill.BilledAmount.HasValue ? oldTActBill.BilledAmount.Value : 0;
                    this.UpdateTBill(bill);
                }

                TBillDet billDetail = this.billDetMgrE.TransferTActBill2TBillDet(oldTActBill);
                billDetail.BillNo = bill.BillNo;
                this.billDetMgrE.CreateTBillDet(billDetail);
                /*
                oldTActBill.BilledAmount = billDetail.BilledAmount;
                oldTActBill.BillAmount = billDetail.BillAmount;
                oldTActBill.IsBilled = true;
                oldTActBill.LastModifyDate = dateTimeNow;
                oldTActBill.LastModifyUser = user.Code;
                oldTActBill.LastModifyUserNm = user.Name;*/
                this.actBillMgrE.UpdateBilled(oldTActBill, billDetail, user);
            }

            return billList;
        }

        [Transaction(TransactionMode.Requires)]
        public void CloseTBill(string billNo, User user)
        {
            TBill oldBill = this.CheckAndLoadTBill(billNo);

            #region 检查状态
            if (oldBill.Status != TMSConstants.CODE_MASTER_TMS_BILLSTATUS_SUBMIT)
            {
                throw new BusinessErrorException("TMS.Bill.Error.StatusErrorWhenClose", oldBill.Status, oldBill.BillNo);
            }
            #endregion
            DateTime now = DateTime.Now;

            //关闭运单
            waybillMgrE.CloseWaybill(oldBill.BillNo, now, user);

            oldBill.Status = TMSConstants.CODE_MASTER_TMS_BILLSTATUS_CLOSE;
            oldBill.LastModifyUser = user.Code;
            oldBill.LastModifyUserNm = user.Name;
            oldBill.LastModifyDate = now;
            oldBill.CloseDate = now;
            oldBill.CloseUser = user.Code;
            oldBill.CloseUserNm = user.Name;

            this.UpdateTBill(oldBill);
        }

        /// <summary>
        /// 驳回
        /// </summary>
        /// <param name="billNo"></param>
        /// <param name="user"></param>
        [Transaction(TransactionMode.Requires)]
        public void VoidTBill(string billNo, User user)
        {
            TBill oldBill = this.CheckAndLoadTBill(billNo);

            #region 检查状态
            if (oldBill.Status != TMSConstants.CODE_MASTER_TMS_BILLSTATUS_CLOSE)
            {
                throw new BusinessErrorException("TMS.Bill.Error.StatusErrorWhenVoid", oldBill.Status, oldBill.BillNo);
            }
            #endregion
            DateTime now = DateTime.Now;
            //退回运单
            waybillMgrE.VoidWaybill(oldBill.BillNo, now, user);

            oldBill.Status = TMSConstants.CODE_MASTER_TMS_BILLSTATUS_SUBMIT;
            oldBill.LastModifyUser = user.Code;
            oldBill.LastModifyUserNm = user.Name;
            oldBill.LastModifyDate = now;
            oldBill.VoidDate = now;
            oldBill.VoidUser = user.Code;
            oldBill.VoidUserNm = user.Name;

            this.UpdateTBill(oldBill);
        }

        [Transaction(TransactionMode.Requires)]
        public void CancelTBill(string billNo, User user)
        {
            TBill oldBill = this.CheckAndLoadTBill(billNo);
            oldBill.TBillDets = this.billDetMgrE.GetTBillDet(billNo);

            #region 检查状态
            if (oldBill.Status != TMSConstants.CODE_MASTER_TMS_BILLSTATUS_SUBMIT)
            {
                throw new BusinessErrorException("TMS.Bill.Error.StatusErrorWhenCancel", oldBill.Status, oldBill.BillNo);
            }
            #endregion

            if (oldBill.TBillDets != null && oldBill.TBillDets.Count > 0)
            {
                foreach (TBillDet newBillDetail in oldBill.TBillDets)
                {
                    TBillDet oldBillDetail = this.billDetMgrE.LoadTBillDet(newBillDetail.Id);

                    //反向更新ActingBill
                    this.actBillMgrE.UpdateBilled(oldBillDetail.ActBill, user);

                    #region 记录开票事务
                    //this.billTransactionMgrE.RecordBillTransaction(oldBillDetail, user, true);
                    #endregion
                }
            }

            oldBill.Status = TMSConstants.CODE_MASTER_TMS_BILLSTATUS_CANCEL;
            oldBill.LastModifyUser = user.Code;
            oldBill.LastModifyUserNm = user.Name;
            oldBill.LastModifyDate = DateTime.Now;
            oldBill.CancelDate = oldBill.LastModifyDate;
            oldBill.CancelUser = user.Code;
            oldBill.CancelUserNm = user.Name;

            this.UpdateTBill(oldBill);
        }

        [Transaction(TransactionMode.Requires)]
        public void UpdateTBill(TBill bill, IList<TBillDet> billDets, User user)
        {
            TBill oldTBill = this.CheckAndLoadTBill(bill.BillNo);
            oldTBill.Discount = bill.Discount;
            oldTBill.ExtBillNo = bill.ExtBillNo;
            oldTBill.BilledAmount = bill.BilledAmount;
            oldTBill.RefBillNo = bill.RefBillNo;

            #region 检查状态
            if (oldTBill.Status != TMSConstants.CODE_MASTER_TMS_BILLSTATUS_CREATE && oldTBill.Status != TMSConstants.CODE_MASTER_TMS_BILLSTATUS_SUBMIT)
            {
                throw new BusinessErrorException("TMS.Bill.Error.StatusErrorWhenUpdate", oldTBill.Status, oldTBill.BillNo);
            }
            #endregion

            #region 更新明细
            if (billDets != null && billDets.Count > 0)
            {
                foreach (TBillDet newTBillDetail in billDets)
                {
                    TBillDet oldTBillDetail = this.billDetMgrE.LoadTBillDet(newTBillDetail.Id);

                    //反向更新ActingTBill，会重新计算开票金额
                    if (oldTBillDetail.BilledAmount != newTBillDetail.BilledAmount)
                    {
                        var actBill = this.actBillMgrE.LoadTActBill(oldTBillDetail.ActBill);
                        actBill.BilledAmount = newTBillDetail.BilledAmount;
                        actBillMgrE.UpdateTActBill(actBill);
                    }

                    oldTBillDetail.BilledAmount = newTBillDetail.BilledAmount;
                    oldTBillDetail.Discount = newTBillDetail.Discount;

                    this.billDetMgrE.UpdateTBillDet(oldTBillDetail);
                }
            }
            #endregion

            oldTBill.LastModifyUser = user.Code;
            oldTBill.LastModifyUserNm = user.Name;
            oldTBill.LastModifyDate = DateTime.Now;
            //oldTBill.BillAmount = billDets.Sum(d => d.BillAmount);

            this.UpdateTBill(oldTBill);
        }

        [Transaction(TransactionMode.Requires)]
        public void SubmitTBill(string billNo, User user)
        {
            TBill oldBill = this.CheckAndLoadTBill(billNo);
            oldBill.TBillDets = this.billDetMgrE.GetTBillDet(billNo);

            #region 检查状态
            if (oldBill.Status != TMSConstants.CODE_MASTER_TMS_BILLSTATUS_CREATE)
            {
                throw new BusinessErrorException("Bill.Error.StatusErrorWhenRelease", oldBill.Status, oldBill.BillNo);
            }
            #endregion

            #region 检查明细不能为空
            if (oldBill.TBillDets == null || oldBill.TBillDets.Count == 0)
            {
                throw new BusinessErrorException("TMS.Bill.Error.EmptyBillDetail", oldBill.BillNo);
            }
            #endregion
            /*
            #region 记录开票事务
            foreach (BillDetail billDetail in oldBill.TBillDets)
            {
                this.billTransactionMgrE.RecordBillTransaction(billDetail, user, false);
            }
            #endregion
            */
            oldBill.Status = TMSConstants.CODE_MASTER_TMS_BILLSTATUS_SUBMIT;
            oldBill.LastModifyUser = user.Code;
            oldBill.LastModifyUserNm = user.Name;
            oldBill.LastModifyDate = DateTime.Now;
            oldBill.SubmitDate = oldBill.LastModifyDate;
            oldBill.SubmitUser = user.Code;
            oldBill.SubmitUserNm = user.Name;

            this.UpdateTBill(oldBill);
        }

        [Transaction(TransactionMode.Unspecified)]
        public TBill LoadTBill(string billNo, bool includeDetail)
        {
            TBill bill = this.CheckAndLoadTBill(billNo);
            if (includeDetail)
            {
                bill.TBillDets = this.billDetMgrE.GetTBillDet(billNo);
            }
            return bill;
        }

        [Transaction(TransactionMode.Requires)]
        public void AddTBillDetail(string billNo, IList<TActBill> actBillList, User user)
        {
            TBill oldBill = this.CheckAndLoadTBill(billNo);

            #region 检查状态
            if (oldBill.Status != TMSConstants.CODE_MASTER_TMS_BILLSTATUS_CREATE)
            {
                throw new BusinessErrorException("TMS.Bill.Error.StatusErrorWhenAddDetail", oldBill.Status, oldBill.BillNo);
            }
            #endregion

            if (actBillList != null && actBillList.Count > 0)
            {
                foreach (TActBill actBill in actBillList)
                {
                    TActBill oldActingBill = this.actBillMgrE.LoadTActBill(actBill.Id);
                    oldActingBill.BilledAmount = actBill.BilledAmount;

                    TBillDet billDetail = this.billDetMgrE.TransferTActBill2TBillDet(oldActingBill);
                    billDetail.BillNo = oldBill.BillNo;

                    this.billDetMgrE.CreateTBillDet(billDetail);

                    if ((oldActingBill.BillAmount.HasValue && oldActingBill.BillAmount.Value != 0)
                         || (oldActingBill.BilledAmount.HasValue && oldActingBill.BilledAmount.Value != 0))
                    {
                        oldBill.BillAmount += oldActingBill.BillAmount.HasValue ? oldActingBill.BillAmount.Value : 0;
                        oldBill.BilledAmount += oldActingBill.BilledAmount.HasValue ? oldActingBill.BilledAmount.Value : 0;
                    }

                    this.actBillMgrE.UpdateBilled(oldActingBill, billDetail, user);
                }

                oldBill.LastModifyDate = DateTime.Now;
                oldBill.LastModifyUser = user.Code;
                oldBill.LastModifyUserNm = user.Name;

                this.UpdateTBill(oldBill);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void DeleteTBillDetail(IList<TBillDet> billDetailList, User user)
        {
            if (billDetailList != null && billDetailList.Count > 0)
            {
                IDictionary<string, TBill> cachedBillDic = new Dictionary<string, TBill>();

                foreach (TBillDet billDetail in billDetailList)
                {
                    TBillDet oldBillDetail = this.billDetMgrE.LoadTBillDet(billDetail.Id);
                    TBill bill = this.CheckAndLoadTBill(oldBillDetail.BillNo);

                    #region 缓存Bill
                    if (!cachedBillDic.ContainsKey(bill.BillNo))
                    {
                        cachedBillDic.Add(bill.BillNo, bill);

                        #region 检查状态
                        if (bill.Status != TMSConstants.CODE_MASTER_TMS_BILLSTATUS_CREATE)
                        {
                            throw new BusinessErrorException("TMS.Bill.Error.StatusErrorWhenDeleteDetail", bill.Status, bill.BillNo);
                        }
                        #endregion
                    }
                    #endregion

                    this.actBillMgrE.UpdateBilled(oldBillDetail.ActBill, user);

                    this.billDetMgrE.DeleteTBillDet(oldBillDetail);

                    bill.BillAmount -= oldBillDetail.BillAmount;
                    bill.BilledAmount -= oldBillDetail.BilledAmount;
                }

                #region 更新Bill
                DateTime dateTimeNow = DateTime.Now;
                foreach (TBill bill in cachedBillDic.Values)
                {
                    bill.LastModifyDate = dateTimeNow;
                    bill.LastModifyUser = user.Code;
                    bill.LastModifyUserNm = user.Name;
                    this.UpdateTBill(bill);
                }
                #endregion
            }
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class TBillMgrE : com.Sconit.TMS.Service.Impl.TBillMgr, ITBillMgrE
    {
    }
}

#endregion Extend Class