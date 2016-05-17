using System;
using System.Linq;
using AutoMapper;
using Castle.Services.Transaction;
using com.Sconit.Entity;
using com.Sconit.Entity.ACC;
using com.Sconit.Entity.BIL;
using com.Sconit.Entity.Exception;
using com.Sconit.Entity.ORD;
using com.Sconit.Entity.MD;
using System.Collections.Generic;
using NHibernate.Criterion;
using System.Text;
using com.Sconit.Entity.VIEW;
using com.Sconit.Entity.FMS;
using com.Sconit.Utility;
using System.Xml;
using com.Sconit.Entity.MES;

namespace com.Sconit.Service.Impl
{
    [Transactional]
    public class FacilityMgrImpl : BaseMgr, IFacilityMgr
    {
        #region 变量
        public IGenericMgr genericMgr { get; set; }
        public INumberControlMgr numberControlMgr { get; set; }
        public IOrderMgr orderMgr { get; set; }
        #endregion

        #region Public Methods

        [Transaction(TransactionMode.Requires)]
        public  void CreateFacilityMaster(FacilityMaster facilityMaster)
        {
            facilityMaster.FCID = numberControlMgr.GetFCID(facilityMaster);
            facilityMaster.Status = CodeMaster.FacilityStatus.Create;
            facilityMaster.CurrChargePersonName = genericMgr.FindById<User>(facilityMaster.CurrChargePersonId).FullName;
            genericMgr.Create(facilityMaster);

            #region 记事务
            FacilityTrans facilityTrans = new FacilityTrans();
            facilityTrans.CreateDate = DateTime.Now;
            facilityTrans.CreateUserId = facilityMaster.CreateUserId;
            facilityTrans.CreateUserName = facilityMaster.CreateUserName;
            facilityTrans.EffDate = DateTime.Now.Date;
            facilityTrans.FCID = facilityMaster.FCID;
            facilityTrans.FromChargePersonId = facilityMaster.CurrChargePersonId;
            facilityTrans.FromChargePersonName = facilityMaster.CurrChargePersonName;
            facilityTrans.FromOrganization = facilityMaster.ChargeOrganization;
            facilityTrans.FromChargeSite = facilityMaster.ChargeSite;
            facilityTrans.ToChargePersonId = facilityMaster.CurrChargePersonId;
            facilityTrans.ToChargePersonName = facilityMaster.CurrChargePersonName;
            facilityTrans.ToOrganization = facilityMaster.ChargeOrganization;
            facilityTrans.ToChargeSite = facilityMaster.ChargeSite;
            facilityTrans.TransType = CodeMaster.FacilityTransType.Create;

            facilityTrans.AssetNo = facilityMaster.AssetNo;
            facilityTrans.FacilityName = facilityMaster.Name;
            facilityTrans.FacilityCategory = facilityMaster.Category;
            genericMgr.Create(facilityTrans);
            #endregion


        }



        [Transaction(TransactionMode.Requires)]
        public void GetFacilityControlPoint(string facilityName)
        {
            string facilityStr =  string.Empty;
            XmlElement controlPointXml =  ObixHelper.Request_WebRequest(facilityName);

            XmlNodeList nodeList = controlPointXml.ChildNodes;
          

            MesScanControlPoint mscp = new MesScanControlPoint();
            mscp.ControlPoint = facilityName;
            mscp.CreateDate = DateTime.Now;
            mscp.Op = "1";                                    
            mscp.OpReference = string.Empty;
            mscp.ProdItem = "";
            mscp.ScanDate = "20160515";
            mscp.ScanTime = "161202";
            mscp.Status = 0;
            mscp.TraceCode = "";
            mscp.Type = CodeMaster.FacilityParamaterType.Scan;
            genericMgr.Create(mscp);
            orderMgr.ReportOrderOp(int.Parse(mscp.Op));

        }


        [Transaction(TransactionMode.Requires)]
        public void GetFacilityParamater(string facilityName)
        {
            string facilityStr = string.Empty;
            XmlElement controlPointXml = ObixHelper.Request_WebRequest(facilityName);

            XmlNodeList nodeList = controlPointXml.ChildNodes;


            MesScanControlPoint mscp = new MesScanControlPoint();
            mscp.ControlPoint = facilityName;
            mscp.CreateDate = DateTime.Now;
            mscp.Op = "1";
            mscp.OpReference = string.Empty;
            mscp.ProdItem = "";
            mscp.ScanDate = "20160515";
            mscp.ScanTime = "161202";
            mscp.Status = 0;
            mscp.TraceCode = "";
            mscp.Note = "";
            mscp.NoteValue = "";
            mscp.Type = CodeMaster.FacilityParamaterType.Paramater;
            genericMgr.Create(mscp);
           

        }


        [Transaction(TransactionMode.Requires)]
        public void CreateFacilityOrder(string facilityName)
        {
            string facilityStr = string.Empty;
            XmlElement controlPointXml = ObixHelper.Request_WebRequest(facilityName);

            XmlNodeList nodeList = controlPointXml.ChildNodes;

            int accQty = 100;
            string fcId = "FC000000008";
            string mpCode = "MP_002";
            IList<FacilityMaintainPlan> facilityMaintainPlanList = genericMgr.FindAll<FacilityMaintainPlan>("from FacilityMaintainPlan f where f.FCID = ? and f.MaintainPlan.Code = ?", new object[] { fcId, mpCode });
            if (facilityMaintainPlanList != null && facilityMaintainPlanList.Count > 0)
            {
                FacilityMaintainPlan facilityMaintainPlan = facilityMaintainPlanList[0];
              

                if (accQty >= facilityMaintainPlan.NextMaintainQty)
                {
                    MaintainPlan maintainPlan = genericMgr.FindById<MaintainPlan>(facilityMaintainPlan.MaintainPlan.Code);

                    FacilityOrderMaster facilityOrderMaster = new FacilityOrderMaster();
                    facilityOrderMaster.FacilityOrderNo = "FO" + DateTime.Now.ToString("yyyyMMddHHmmss");
                    facilityOrderMaster.Status = CodeMaster.FacilityOrderStatus.Submit;
                    facilityOrderMaster.Type = CodeMaster.FacilityOrderType.Maintain;
                    facilityOrderMaster.ReferenceNo = maintainPlan.Description;
                    facilityOrderMaster.Region = string.Empty;
                    genericMgr.Create(facilityOrderMaster);

                
                    IList<MaintainPlanItem>maintainPlanItemList = genericMgr.FindAll<MaintainPlanItem>("from MaintainPlanItem m where m.MaintainPlanCode = ?", new object[] {  mpCode });
                    foreach (MaintainPlanItem maintainPlanItem in maintainPlanItemList)
                    {
                        FacilityOrderDetail facilityOrderDetail = new FacilityOrderDetail();
                        facilityOrderDetail.FacilityOrderNo = facilityOrderMaster.FacilityOrderNo;
                        facilityOrderDetail.BaseUom = maintainPlanItem.BaseUom;
                        facilityOrderDetail.FacilityId = facilityMaintainPlan.FCID;
                        facilityOrderDetail.Item = maintainPlanItem.Item;
                        facilityOrderDetail.ItemDescription = maintainPlanItem.ItemDescription;
                        facilityOrderDetail.PlanQty = maintainPlanItem.Qty;
                        facilityOrderDetail.Sequence = maintainPlanItem.Sequence;
                        facilityOrderDetail.Uom = maintainPlanItem.Uom;
                        genericMgr.Create(facilityOrderDetail);
                        facilityOrderMaster.AddFacilityOrderDetail(facilityOrderDetail);
                    }

                    #region 更新下次保养数量
                    facilityMaintainPlan.NextMaintainQty += maintainPlan.TypePeriod;
                    genericMgr.Update(facilityMaintainPlan);
                    #endregion
                }

               
            }
          

        }



        [Transaction(TransactionMode.Requires)]
        public void GenerateFacilityMaintainPlan()
        {

            #region 取所有到时间的预防计划的设施
            DetachedCriteria criteria = DetachedCriteria.For(typeof(FacilityMaintainPlan));
            criteria.Add (Expression.And(Expression.IsNotNull("NextWarnDate"), Expression.Le("NextWarnDate", DateTime.Now)));
            IList<FacilityMaintainPlan> facilityMaintainPlanList = genericMgr.FindAll<FacilityMaintainPlan>(criteria);
            #endregion

            #region 生成ISI任务
           
            if (facilityMaintainPlanList != null && facilityMaintainPlanList.Count > 0)
            {

                foreach (FacilityMaintainPlan facilityPlan in facilityMaintainPlanList)
                {
                    #region 生成ISI任务
                    MaintainPlan maintainPlan = genericMgr.FindById<MaintainPlan>(facilityPlan.MaintainPlan.Code);

                    FacilityOrderMaster facilityOrderMaster = new FacilityOrderMaster();
                    facilityOrderMaster.FacilityOrderNo = "FO" + DateTime.Now.ToString("yyyyMMddHHmmss");
                    facilityOrderMaster.Status = CodeMaster.FacilityOrderStatus.Submit;
                    facilityOrderMaster.Type = CodeMaster.FacilityOrderType.Maintain;
                    facilityOrderMaster.ReferenceNo = maintainPlan.Description;
                    facilityOrderMaster.Region = string.Empty;
                    genericMgr.Create(facilityOrderMaster);


                    IList<MaintainPlanItem> maintainPlanItemList = genericMgr.FindAll<MaintainPlanItem>("from MaintainPlanItem m where m.MaintainPlanCode = ?", new object[] { facilityPlan.MaintainPlan.Code });
                    foreach (MaintainPlanItem maintainPlanItem in maintainPlanItemList)
                    {
                        FacilityOrderDetail facilityOrderDetail = new FacilityOrderDetail();
                        facilityOrderDetail.FacilityOrderNo = facilityOrderMaster.FacilityOrderNo;
                        facilityOrderDetail.BaseUom = maintainPlanItem.BaseUom;
                        facilityOrderDetail.FacilityId = facilityPlan.FCID;
                        facilityOrderDetail.Item = maintainPlanItem.Item;
                        facilityOrderDetail.ItemDescription = maintainPlanItem.ItemDescription;
                        facilityOrderDetail.PlanQty = maintainPlanItem.Qty;
                        facilityOrderDetail.Sequence = maintainPlanItem.Sequence;
                        facilityOrderDetail.Uom = maintainPlanItem.Uom;
                        genericMgr.Create(facilityOrderDetail);
                        facilityOrderMaster.AddFacilityOrderDetail(facilityOrderDetail);
                    }
                    #endregion

                    #region 更新下次时间、数量
                    if (facilityPlan.MaintainPlan.Type == CodeMaster.MaintainPlanType.Once)
                    {
                        facilityPlan.NextMaintainDate = null;
                        facilityPlan.NextWarnDate = null;
                    }
                    else
                    {
                        #region 现在周期都维护
                        if (facilityPlan.MaintainPlan.Type == CodeMaster.MaintainPlanType.Minute)
                        {
                            facilityPlan.NextMaintainDate = facilityPlan.NextMaintainDate.Value.AddMinutes(facilityPlan.MaintainPlan.TypePeriod);
                            facilityPlan.NextWarnDate = facilityPlan.NextWarnDate.Value.AddMinutes(facilityPlan.MaintainPlan.TypePeriod);
                        }
                        else if (facilityPlan.MaintainPlan.Type == CodeMaster.MaintainPlanType.Hour)
                        {
                            facilityPlan.NextMaintainDate = facilityPlan.NextMaintainDate.Value.AddHours(facilityPlan.MaintainPlan.TypePeriod);
                            facilityPlan.NextWarnDate = facilityPlan.NextWarnDate.Value.AddHours(facilityPlan.MaintainPlan.TypePeriod);
                        }
                        else if (facilityPlan.MaintainPlan.Type == CodeMaster.MaintainPlanType.Day)
                        {
                            facilityPlan.NextMaintainDate = facilityPlan.NextMaintainDate.Value.AddDays(facilityPlan.MaintainPlan.TypePeriod);
                            facilityPlan.NextWarnDate = facilityPlan.NextWarnDate.Value.AddDays(facilityPlan.MaintainPlan.TypePeriod);
                        }
                        else if (facilityPlan.MaintainPlan.Type == CodeMaster.MaintainPlanType.Week)
                        {
                            facilityPlan.NextMaintainDate = facilityPlan.NextMaintainDate.Value.AddDays(7 * facilityPlan.MaintainPlan.TypePeriod);
                            facilityPlan.NextWarnDate = facilityPlan.NextWarnDate.Value.AddDays(7 * facilityPlan.MaintainPlan.TypePeriod);
                        }
                        else if (facilityPlan.MaintainPlan.Type == CodeMaster.MaintainPlanType.Month)
                        {
                            facilityPlan.NextMaintainDate = facilityPlan.NextMaintainDate.Value.AddMonths(facilityPlan.MaintainPlan.TypePeriod);
                            facilityPlan.NextWarnDate = facilityPlan.NextWarnDate.Value.AddMonths(facilityPlan.MaintainPlan.TypePeriod);
                        }
                        else if (facilityPlan.MaintainPlan.Type == CodeMaster.MaintainPlanType.Year)
                        {
                            facilityPlan.NextMaintainDate = facilityPlan.NextMaintainDate.Value.AddYears(facilityPlan.MaintainPlan.TypePeriod);
                            facilityPlan.NextWarnDate = facilityPlan.NextWarnDate.Value.AddYears(facilityPlan.MaintainPlan.TypePeriod);
                        }
                        #endregion
                    }

                    genericMgr.Update(facilityPlan);
                    #endregion
                }
            }
            #endregion
        }




        [Transaction(TransactionMode.Requires)]
        public void CreateCheckListOrder(string checkListCode)
        {
            CheckListMaster checkListMaster = genericMgr.FindById<CheckListMaster>(checkListCode);

            IList<CheckListDetail> checkListOrderDetailList = genericMgr.FindAll<CheckListDetail>("from CheckListOrderDetail c where c.CheckListCode = ?", new object[] { checkListCode });

            CheckListOrderMaster checkListOrderMaster = new CheckListOrderMaster();
           
        
        }
        #endregion

        #region Private Methods

      

        #endregion



    }
}
