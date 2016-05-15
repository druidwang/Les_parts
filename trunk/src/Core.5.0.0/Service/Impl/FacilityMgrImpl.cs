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
          

            MESScanControlPoint mscp = new MESScanControlPoint();
            mscp.ControlPoint = facilityName;
            mscp.CreateDate = DateTime.Now;
            mscp.Op = "1";                                    
            mscp.OpReference = string.Empty;
            mscp.ProdItem = "";
            mscp.ScanDate = "20160515";
            mscp.ScanTime = "161202";
            mscp.Status = 0;
            mscp.TraceCode = "";
            genericMgr.Create(mscp);

        }

        #endregion

        #region Private Methods

      

        #endregion



    }
}
