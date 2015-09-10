using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.TMS.Persistence;
using com.Sconit.Service;
using com.Sconit.TMS.Entity;
using com.Sconit.Service.Ext.MasterData;
using com.Sconit.TMS.Service.Util;
using com.Sconit.Entity;
using com.Sconit.ISI.Service.Ext;
using com.Sconit.Entity.MasterData;
using com.Sconit.Entity.Exception;
using NHibernate.Expression;
using com.Sconit.Service.Ext.Criteria;
using com.Sconit.ISI.Service.Ext;
using com.Sconit.TMS.Service.Ext;
using com.Sconit.ISI.Entity.Util;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class FreightMgr : FreightBaseMgr, IFreightMgr
    {
        //public IWaybillDao waybillDao { get; set; }
        public IEntityPreferenceMgrE entityPreferenceMgrE { get; set; }
        public ICarrierMgrE carrierMgrE { get; set; }
        public ITaskMgrE taskMgrE { get; set; }
        public IUserMgrE userMgrE { get; set; }
        public INumberControlMgrE numberControlMgrE { get; set; }
        public ICriteriaMgrE criteriaMgrE { get; set; }

        #region Customized Methods
        [Transaction(TransactionMode.Unspecified)]
        public IList<Freight> GetFreight(string carrier, string shipFrom, string shipTo)
        {
            return GetFreight(string.Empty, carrier, shipFrom, shipTo);
        }
        [Transaction(TransactionMode.Unspecified)]
        public IList<Freight> GetFreight(string freightNo, string carrier, string shipFrom, string shipTo)
        {
            DetachedCriteria criteria = DetachedCriteria.For(typeof(Freight));
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
            if (!string.IsNullOrEmpty(freightNo))
            {
                criteria.Add(Expression.Or(Expression.Eq("Status", TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_SUBMIT), Expression.Eq("FreightNo", freightNo)));
            }
            else
            {
                criteria.Add(Expression.Eq("Status", TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_SUBMIT));
            }
            return criteriaMgrE.FindAll<Freight>(criteria);

        }

        [Transaction(TransactionMode.Unspecified)]
        public Freight CheckAndLoadFreight(string freightNo)
        {
            Freight freight = this.LoadFreight(freightNo);
            if (freight != null)
            {
                return freight;
            }
            else
            {
                throw new BusinessErrorException("TMS.Error.FreightNoNotExist", freightNo);
            }
        }

        [Transaction(TransactionMode.Requires)]
        public void SubmitFreight(string freightNo, User user)
        {
            Freight freight = this.CheckAndLoadFreight(freightNo);
            if (freight.Status != TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CREATE)
            {
                throw new BusinessErrorException("TMS.Error.StatusErrorWhenSubmit", freight.Status, freight.FreightNo);
            }

            freight.Status = TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_SUBMIT;
            freight.Comment = "邮件快速审批";
            DateTime now = DateTime.Now;
            freight.LastModifyDate = now;
            freight.LastModifyUser = user.Code;
            freight.LastModifyUserNm = user.Name;
            freight.SubmitDate = now;
            freight.SubmitUser = user.Code;
            freight.SubmitUserNm = user.Name;

            this.UpdateFreight(freight);
            string mailTo = carrierMgrE.LoadCarrier(freight.Carrier).FreightEmail;
            //提醒创建人
            if (user.Code != freight.CreateUser)
            {
                if (!string.IsNullOrEmpty(mailTo))
                {
                    mailTo += ";" + userMgrE.LoadUser(freight.CreateUser).Email;
                }
                else
                {
                    mailTo = userMgrE.LoadUser(freight.CreateUser).Email;
                }
            }
            Remind(freight, mailTo);

        }
        [Transaction(TransactionMode.Requires)]
        public void SubmitFreight(Freight freight, User user)
        {
            Freight oldFreight = this.CheckAndLoadFreight(freight.FreightNo);

            if (oldFreight.Status != TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CREATE)
            {
                throw new BusinessErrorException("TMS.Error.StatusErrorWhenSubmit", oldFreight.Status, oldFreight.FreightNo);
            }

            oldFreight.Status = TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_SUBMIT;

            DateTime now = DateTime.Now;

            //oldFreight.WaybillNo = freight.WaybillNo;
            oldFreight.Reason = freight.Reason;
            oldFreight.Remark = freight.Remark;
            oldFreight.ShipFrom = freight.ShipFrom;
            oldFreight.ShipFromDesc = freight.ShipFromDesc;
            oldFreight.ShipTo = freight.ShipTo;
            oldFreight.ShipToDesc = freight.ShipToDesc;
            oldFreight.Freight = freight.Freight;
            oldFreight.Currency = freight.Currency;
            oldFreight.Comment = freight.Comment;
            oldFreight.CarrierDesc = freight.CarrierDesc;
            oldFreight.Carrier = freight.Carrier;

            oldFreight.LastModifyDate = now;
            oldFreight.LastModifyUser = user.Code;
            oldFreight.LastModifyUserNm = user.Name;
            oldFreight.SubmitDate = now;
            oldFreight.SubmitUser = user.Code;
            oldFreight.SubmitUserNm = user.Name;

            this.UpdateFreight(oldFreight);
            string mailTo = carrierMgrE.LoadCarrier(freight.Carrier).FreightEmail;
            //提醒创建人
            if (user.Code != oldFreight.CreateUser)
            {
                if (!string.IsNullOrEmpty(mailTo))
                {
                    mailTo += ";" + userMgrE.LoadUser(oldFreight.CreateUser).Email;
                }
                else
                {
                    mailTo = userMgrE.LoadUser(oldFreight.CreateUser).Email;
                }
            }
            Remind(oldFreight, mailTo);
        }

        [Transaction(TransactionMode.Requires)]
        public void CancelFreight(string freightNo, User user)
        {
            Freight freight = this.CheckAndLoadFreight(freightNo);

            if (freight.Status != TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CREATE)
            {
                throw new BusinessErrorException("TMS.Error.StatusErrorWhenCancel", freight.Status, freight.FreightNo);
            }

            freight.Status = TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CANCEL;

            DateTime now = DateTime.Now;


            freight.Comment = "邮件快速拒绝";

            freight.LastModifyDate = now;
            freight.LastModifyUser = user.Code;
            freight.LastModifyUserNm = user.Name;
            freight.CancelDate = now;
            freight.CancelUser = user.Code;
            freight.CancelUserNm = user.Name;

            this.UpdateFreight(freight);

            string mailTo = carrierMgrE.LoadCarrier(freight.Carrier).FreightEmail;
            //提醒创建人
            if (user.Code != freight.CreateUser)
            {
                if (!string.IsNullOrEmpty(mailTo))
                {
                    mailTo += ";" + userMgrE.LoadUser(freight.CreateUser).Email;
                }
                else
                {
                    mailTo = userMgrE.LoadUser(freight.CreateUser).Email;
                }
            }
            Remind(freight, mailTo);
        }

        [Transaction(TransactionMode.Requires)]
        public void CancelFreight(Freight freight, User user)
        {
            Freight oldFreight = this.CheckAndLoadFreight(freight.FreightNo);

            if (oldFreight.Status != TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CREATE)
            {
                throw new BusinessErrorException("TMS.Error.StatusErrorWhenCancel", oldFreight.Status, oldFreight.FreightNo);
            }

            oldFreight.Status = TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CANCEL;

            DateTime now = DateTime.Now;

            //oldFreight.WaybillNo = freight.WaybillNo;
            oldFreight.Reason = freight.Reason;
            oldFreight.Remark = freight.Remark;
            oldFreight.ShipFrom = freight.ShipFrom;
            oldFreight.ShipFromDesc = freight.ShipFromDesc;
            oldFreight.ShipTo = freight.ShipTo;
            oldFreight.ShipToDesc = freight.ShipToDesc;
            oldFreight.Freight = freight.Freight;
            oldFreight.Currency = freight.Currency;
            oldFreight.Comment = freight.Comment;
            oldFreight.CarrierDesc = freight.CarrierDesc;
            oldFreight.Carrier = freight.Carrier;
            oldFreight.LastModifyDate = now;
            oldFreight.LastModifyUser = user.Code;
            oldFreight.LastModifyUserNm = user.Name;
            oldFreight.CancelDate = now;
            oldFreight.CancelUser = user.Code;
            oldFreight.CancelUserNm = user.Name;

            this.UpdateFreight(oldFreight);

            string mailTo = carrierMgrE.LoadCarrier(freight.Carrier).FreightEmail;
            //提醒创建人
            if (user.Code != oldFreight.CreateUser)
            {
                if (!string.IsNullOrEmpty(mailTo))
                {
                    mailTo += ";" + userMgrE.LoadUser(oldFreight.CreateUser).Email;
                }
                else
                {
                    mailTo = userMgrE.LoadUser(oldFreight.CreateUser).Email;
                }
            }
            Remind(oldFreight, mailTo);
        }

        [Transaction(TransactionMode.Requires)]
        public void CloseFreight(string freightNo, User user)
        {
            Freight freight = this.CheckAndLoadFreight(freightNo);

            //检查状态
            if (freight.Status != TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_SUBMIT)
            {
                throw new BusinessErrorException("TMS.Error.StatusErrorWhenClose", freight.Status, freight.FreightNo);
            }

            freight.Status = TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CLOSE;

            DateTime now = DateTime.Now;

            freight.LastModifyDate = now;
            freight.LastModifyUser = user.Code;
            freight.LastModifyUserNm = user.Name;
            freight.CloseDate = now;
            freight.CloseUser = user.Code;
            freight.CloseUserNm = user.Name;
            this.UpdateFreight(freight);
        }

        [Transaction(TransactionMode.Requires)]
        public void CloseFreight(string freightNo, string waybillNo, string userCode, string userName)
        {
            var freight = this.CheckAndLoadFreight(freightNo);
            this.CloseFreight(freight, waybillNo, userCode, userName);
        }

        [Transaction(TransactionMode.Requires)]
        public void CloseFreight(Freight freight, string waybillNo, string userCode, string userName)
        {
            if (freight.Status == TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CLOSE) return;
            freight.Status = TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CLOSE;

            DateTime now = DateTime.Now;

            freight.WaybillNo = waybillNo;
            freight.LastModifyDate = now;
            freight.LastModifyUser = userCode;
            freight.LastModifyUserNm = userName;
            freight.CloseDate = now;
            freight.CloseUser = userCode;
            freight.CloseUserNm = userName;
            this.UpdateFreight(freight);
        }

        [Transaction(TransactionMode.Requires)]
        public void OpenFreight(string freightNo, string userCode, string userName)
        {
            var freight = this.LoadFreight(freightNo);
            if (freight.Status != TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CLOSE) return;
            freight.Status = TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_SUBMIT;

            DateTime now = DateTime.Now;

            freight.WaybillNo = string.Empty;
            freight.LastModifyDate = now;
            freight.LastModifyUser = userCode;
            freight.LastModifyUserNm = userName;
            freight.CloseDate = null;
            freight.CloseUser = string.Empty;
            freight.CloseUserNm = string.Empty;
            this.UpdateFreight(freight);
        }

        [Transaction(TransactionMode.Requires)]
        public override void CreateFreight(Freight freight)
        {
            freight.Status = TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CREATE;
            freight.FreightNo = numberControlMgrE.GenerateNumber(TMSConstants.CODE_PREFIX_FREIGHT);

            base.CreateFreight(freight);

            //审批提醒
            IList<object[]> users = userMgrE.FindUserByPermission(new string[] { TMSConstants.PERMISSION_PAGE_VALUE_FREIGHTRELEASE });

            Remind(freight, users);
            //订阅功能
            string mailTo = carrierMgrE.LoadCarrier(freight.Carrier).FreightEmail;
            Remind(freight, mailTo);
        }


        /// <summary>
        /// 审批
        /// </summary>
        /// <param name="freight"></param>
        /// <param name="users"></param>
        [Transaction(TransactionMode.Requires)]
        protected void Remind(Freight freight, IList<object[]> users)
        {
            string subject = freight.LastModifyUserNm + "提交运费申请" + freight.FreightNo + "，请审批";
            string companyName = entityPreferenceMgrE.LoadEntityPreference(BusinessConstants.ENTITY_PREFERENCE_CODE_COMPANYNAME).Value;
            string webAddress = "localhost:2012/";
            if (!companyName.Contains("TEST"))
            {
                webAddress = entityPreferenceMgrE.LoadEntityPreference(ISIConstants.ENTITY_PREFERENCE_WEBADDRESS).Value;
            }
            if (users != null && users.Count > 0)
            {
                StringBuilder body = GetBody(freight);
                foreach (var user in users)
                {
                    StringBuilder releaseStr = new StringBuilder();
                    releaseStr.Append(body);
                    releaseStr.Append(BusinessConstants.EMAIL_SEPRATOR);
                    releaseStr.Append("您可点击 ");

                    releaseStr.Append("<a href='http://" + webAddress + "/TMS/Freight/FreightHandler.ashx?FreightNo=" + freight.FreightNo + "&UserCode=" + user[0].ToString() + "&UserPwd=" + user[1].ToString() + "&Type=1' >");

                    releaseStr.Append("同意");
                    releaseStr.Append("<a/>");
                    releaseStr.Append(" 快速审批");
                    releaseStr.Append(BusinessConstants.EMAIL_SEPRATOR);
                    releaseStr.Append(" 或您可点击 ");

                    releaseStr.Append("<a href='http://" + webAddress + "/TMS/Freight/FreightHandler.ashx?FreightNo=" + freight.FreightNo + "&UserCode=" + user[0].ToString() + "&UserPwd=" + user[1].ToString() + "&Type=0' >");

                    releaseStr.Append("不同意");
                    releaseStr.Append("<a/>");

                    taskMgrE.Remind(subject, releaseStr, user[2].ToString());
                    //taskMgrE.Remind(subject, releaseStr, "tiansu@yfgm.com.cn");
                }
            }
        }
        private StringBuilder GetBody(Freight freight)
        {
            StringBuilder body = new StringBuilder();
            body.Append("您好:");
            body.Append(BusinessConstants.EMAIL_SEPRATOR);
            body.Append(BusinessConstants.EMAIL_SEPRATOR);
            body.Append("状&nbsp;&nbsp;态：");
            if (freight.Status == TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CREATE)
            {
                body.Append("创建");
            }
            if (freight.Status == TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_SUBMIT)
            {
                body.Append("批准");
            }
            if (freight.Status == TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CANCEL)
            {
                body.Append("取消");
            }
            body.Append(BusinessConstants.EMAIL_SEPRATOR);
            body.Append("承运商：" + freight.CarrierDesc + BusinessConstants.EMAIL_SEPRATOR);
            body.Append("始发地：" + freight.ShipFromDesc + BusinessConstants.EMAIL_SEPRATOR);
            body.Append("目的地：" + freight.ShipToDesc + BusinessConstants.EMAIL_SEPRATOR);
            body.Append("币&nbsp;&nbsp;种：" + freight.Currency + BusinessConstants.EMAIL_SEPRATOR);
            body.Append("金&nbsp;&nbsp;额：" + freight.Freight.ToString("0.########") + BusinessConstants.EMAIL_SEPRATOR);
            body.Append("事&nbsp;&nbsp;由：" + (!string.IsNullOrEmpty(freight.Reason) ? freight.Reason.Replace(BusinessConstants.TEXT_SEPRATOR, BusinessConstants.EMAIL_SEPRATOR) : string.Empty) + BusinessConstants.EMAIL_SEPRATOR);
            body.Append("备&nbsp;&nbsp;注：" + (!string.IsNullOrEmpty(freight.Remark) ? freight.Remark.Replace(BusinessConstants.TEXT_SEPRATOR, BusinessConstants.EMAIL_SEPRATOR) : string.Empty) + BusinessConstants.EMAIL_SEPRATOR);
            if (freight.Status != TMSConstants.CODE_MASTER_TMS_FREIGHTSTATUS_CREATE)
            {
                body.Append("批&nbsp;&nbsp;示：" + (!string.IsNullOrEmpty(freight.Comment) ? freight.Comment.Replace(BusinessConstants.TEXT_SEPRATOR, BusinessConstants.EMAIL_SEPRATOR) : string.Empty) + BusinessConstants.EMAIL_SEPRATOR);
            }

            body.Append(BusinessConstants.EMAIL_SEPRATOR);
            body.Append(BusinessConstants.EMAIL_SEPRATOR);
            body.Append(freight.CreateUserNm + BusinessConstants.EMAIL_SEPRATOR);
            body.Append(freight.CreateDate.ToString("yyyy-MM-dd HH:mm") + BusinessConstants.EMAIL_SEPRATOR);

            return body;
        }

        [Transaction(TransactionMode.Requires)]
        protected void Remind(Freight freight, string mailTo)
        {
            try
            {
                if (string.IsNullOrEmpty(mailTo)) return;
                string subject = "通知 运费申请单" + freight.FreightNo;
                StringBuilder body = GetBody(freight);

                taskMgrE.Remind(subject, body, mailTo);

            }
            catch (Exception e)
            {
            }
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class FreightMgrE : com.Sconit.TMS.Service.Impl.FreightMgr, IFreightMgrE
    {
    }
}

#endregion Extend Class