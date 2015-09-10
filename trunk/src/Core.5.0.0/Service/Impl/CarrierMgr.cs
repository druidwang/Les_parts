using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.TMS.Persistence;
using com.Sconit.Service;
using com.Sconit.Service.Ext.MasterData;
using com.Sconit.Persistence.MasterData;
using com.Sconit.Persistence;
using com.Sconit.Service.Ext.Criteria;
using com.Sconit.TMS.Entity;
using com.Sconit.Entity.MasterData;
using com.Sconit.TMS.Service.Util;
using System.Data.SqlClient;
using System.Data;
using NHibernate.Expression;
using com.Sconit.TMS.Service.Ext;
using System.Linq;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class CarrierMgr : CarrierBaseMgr, ICarrierMgr
    {
        public IAddressMgrE addressMgrE { get; set; }
        public ICriteriaMgrE criteriaMgrE { get; set; }
        public IPermissionMgrE permissionMgrE { get; set; }
        public IPermissionCategoryMgrE permissionCategoryMgrE { get; set; }
        public IUserPermissionMgrE userPermissionMgrE { get; set; }
        public IPartyDao partyDao { get; set; }
        public ISqlHelperDao sqlHelperDao { get; set; }
        public IUserMgrE userMgrE { get; set; }
        public ICodeMasterMgrE codeMasterMgrE { get; set; }
        public ITFlowDetMgrE flowDetMgrE { get; set; }
        public ILanguageMgrE languageMgrE { get; set; }

        #region Customized Methods
        [Transaction(TransactionMode.Requires)]
        public override void CreateCarrier(Carrier entity)
        {
            CreateCarrier(entity, userMgrE.GetMonitorUser());
        }

        [Transaction(TransactionMode.Requires)]
        public void CreateCarrier(Carrier entity, User currentUser)
        {
            if (partyDao.LoadParty(entity.Code) == null)
            {
                base.CreateCarrier(entity);
            }
            else
            {
                CreateCarrierOnly(entity);
            }
            Permission permission = new Permission();
            permission.Category = permissionCategoryMgrE.LoadPermissionCategory(TMSConstants.CODE_MASTER_PERMISSION_CATEGORY_TYPE_VALUE_CARRIER);
            permission.Code = entity.Code;
            permission.Description = entity.Name;
            permissionMgrE.CreatePermission(permission);
            UserPermission userPermission = new UserPermission();
            userPermission.Permission = permission;
            userPermission.User = currentUser;
            userPermissionMgrE.CreateUserPermission(userPermission);
        }


        [Transaction(TransactionMode.Unspecified)]
        public int CreateCarrierOnly(Carrier entity)
        {
            string sql = "insert into TMS_Carrier(code) values(@code) ";

            SqlParameter[] param = new SqlParameter[1];
            param[0] = new SqlParameter("@code", SqlDbType.NVarChar, 50);
            param[0].Value = entity.Code;
            return sqlHelperDao.Create(sql, param);
        }

        [Transaction(TransactionMode.Requires)]
        public override void DeleteCarrier(string code)
        {
            IList<UserPermission> userPermissionList = userPermissionMgrE.GetUserPermission(code);
            userPermissionMgrE.DeleteUserPermission(userPermissionList);
            permissionMgrE.DeletePermission(code);

            if (partyDao.LoadParty(code) == null)
            {
                DeleteCarrierOnly(code);
            }
            else
            {
                addressMgrE.DeleteAddressByParent(code);
                base.DeleteCarrier(code);
            }
        }

        [Transaction(TransactionMode.Unspecified)]
        public int DeleteCarrierOnly(string code)
        {
            string sql = "delete from TMS_Carrier where code=@code ";

            SqlParameter[] param = new SqlParameter[1];
            param[0] = new SqlParameter("@code", SqlDbType.NVarChar, 50);
            param[0].Value = code;
            return sqlHelperDao.Delete(sql, param);
        }

        [Transaction(TransactionMode.Requires)]
        public override void DeleteCarrier(Carrier carrier)
        {
            DeleteCarrier(carrier.Code);
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<Carrier> GetCarrier(string userCode, string flowCode)
        {
            IList<Carrier> carrierList = GetCarrier(userCode, false);
            if (carrierList != null && carrierList.Count > 0 && !string.IsNullOrEmpty(flowCode))
            {
                IList<TFlowDet> flowDetList = this.flowDetMgrE.GetTFlowDet(flowCode);
                if (flowDetList != null && flowDetList.Count > 0)
                {
                    var codeMstrList = codeMasterMgrE.GetCachedCodeMaster(TMSConstants.CODE_MASTER_TMS_PRICELIST);
                    var carrierCodeList = flowDetList.Select(f => f.Carrier).Distinct().ToList();
                    for (int i = carrierCodeList.Count - 1; i >= 0; i--)
                    {
                        var cList = carrierList.Where(c => c.Code == carrierCodeList[i]).ToList();
                        if (cList != null && cList.Count > 0)
                        {                            
                            var flwoDetTList = flowDetList.Where(f => f.Carrier == carrierCodeList[i]).ToList();
                            if (cList[0].PricingMethod == null)
                            {
                                cList[0].PricingMethod = string.Empty;
                            }
                            foreach (var f in flwoDetTList)
                            {
                                carrierList.Remove(cList[0]);
                                var codeList = codeMstrList.Where(c => c.Value == f.PricingMethod);
                                if (!string.IsNullOrEmpty(cList[0].PricingMethod))
                                {
                                    cList[0].PricingMethod += " - ";
                                }
                                if (codeList != null && codeList.Count() > 0)
                                {
                                    cList[0].PricingMethod += codeList.FirstOrDefault().Description;
                                }
                                else
                                {
                                    cList[0].PricingMethod += languageMgrE.TranslateMessage("TMS.FlowDetail.Free", userCode);
                                }
                                carrierList.Insert(0, cList[0]);
                            }
                        }
                    }
                }
            }
            return carrierList;
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<Carrier> GetCarrier(string userCode)
        {
            return GetCarrier(userCode, false);
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<Carrier> GetCarrier(string userCode, bool includeInactive)
        {
            DetachedCriteria criteria = DetachedCriteria.For<Carrier>();
            if (!includeInactive)
            {
                criteria.Add(Expression.Eq("IsActive", true));
            }

            DetachedCriteria[] pCrieteria = TMSUtil.GetCarrierPermissionCriteria(userCode);

            criteria.Add(
                Expression.Or(
                    Subqueries.PropertyIn("Code", pCrieteria[0]),
                    Subqueries.PropertyIn("Code", pCrieteria[1])));

            return criteriaMgrE.FindAll<Carrier>(criteria);
        }
        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class CarrierMgrE : com.Sconit.TMS.Service.Impl.CarrierMgr, ICarrierMgrE
    {
    }
}

#endregion Extend Class