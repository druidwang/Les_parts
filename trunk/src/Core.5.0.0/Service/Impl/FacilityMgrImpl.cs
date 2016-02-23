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

namespace com.Sconit.Service.Impl
{
    [Transactional]
    public class FacilityImpl : BaseMgr, IFacilityMgr
    {
        #region 变量
        public IGenericMgr genericMgr { get; set; }
        public INumberControlMgr numberControlMgr { get; set; }
      
        #endregion

        #region Public Methods

        [Transaction(TransactionMode.Requires)]
        public  void CreateFacilityMaster(FacilityMaster facilityMaster)
        {
            genericMgr.Create(facilityMaster);

            #region 记事务

            FacilityTrans facilityTrans = new FacilityTrans();
            facilityTrans.CreateDate = DateTime.Now;
            facilityTrans.CreateUser = facilityMaster.CreateUser;
            facilityTrans.EffDate = DateTime.Now.Date;
            facilityTrans.FCID = facilityMaster.FCID;
            facilityTrans.FromChargePerson = facilityMaster.CurrChargePerson;
            facilityTrans.FromChargePersonName = facilityMaster.CurrChargePersonName;
            facilityTrans.FromOrganization = facilityMaster.ChargeOrganization;
            facilityTrans.FromChargeSite = facilityMaster.ChargeSite;
            facilityTrans.ToChargePerson = facilityMaster.CurrChargePerson;
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
        #endregion

        #region Private Methods

      

        #endregion



    }
}
