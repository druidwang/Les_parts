using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.Persistence;
using com.Sconit.TMS.Entity;
using com.Sconit.Service.Ext.Hql;
using com.Sconit.Entity;
using com.Sconit.Service.Ext.Criteria;
using NHibernate.Expression;
using com.Sconit.Entity.MasterData;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class WaybillDetMgr : WaybillDetBaseMgr, IWaybillDetMgr
    {
        public IHqlMgrE hqlMgrE { get; set; }
        public ICriteriaMgrE criteriaMgrE { get; set; }

        #region Customized Methods
        /// <summary>
        /// 不建议使用
        /// </summary>
        /// <param name="ipNo"></param>
        /// <param name="includeTransited"></param>
        /// <returns></returns>
        [Transaction(TransactionMode.Unspecified)]
        public WaybillDet GetWaybillDet(string ipNo, bool includeTransited)
        {
            StringBuilder hql = new StringBuilder();
            hql.Append("select ip.IpNo,ip.Status,ip.DockDescription,ip.WaybillNo,ip.DepartTime,ip.ArriveTime ");
            hql.Append("        ,u.Code,u.FirstName,u.LastName  ");
            hql.Append("        ,pf.Code ,pf.Name ,pt.Code ,pt.Name ,");
            hql.Append("        sf.Code ,sf.Address ,st.Code ,st.Address , ");
            hql.Append("        sum(ipd.Qty/ipd.HuLotSize) ");
            hql.Append("from InProcessLocation ip ");
            hql.Append("join ip.CreateUser u ");
            hql.Append("join ip.PartyFrom pf join ip.PartyTo pt ");
            hql.Append("join ip.ShipFrom sf join ip.ShipTo st ");
            hql.Append("left join ip.InProcessLocationDetails ipd ");
            hql.Append("where  ipd.HuLotSize !=0 ");//
            hql.Append("  and  ip.OrderType !='" + BusinessConstants.CODE_MASTER_ORDER_TYPE_VALUE_PRODUCTION + "' ");
            if (!includeTransited)
            {
                hql.Append(" and (ip.WaybillNo is null or ip.WaybillNo ='') ");
                hql.Append(" and ip.Status != '" + BusinessConstants.CODE_MASTER_STATUS_VALUE_CLOSE + "' ");
            }
            hql.Append("and   ip.IpNo=:IpNo ");
            hql.Append("group by ip.IpNo,ip.Status,ip.DockDescription,ip.WaybillNo,ip.DepartTime,ip.ArriveTime,");
            hql.Append("        u.Code,u.FirstName,u.LastName,");
            hql.Append("        pf.Code,pf.Name,pt.Code,pt.Name,");
            hql.Append("        sf.Code,sf.Address ,st.Code ,st.Address ");
            IDictionary<string, object> param = new Dictionary<string, object>();
            param.Add("IpNo", ipNo);
            var waybillDetList = this.hqlMgrE.FindAll<object[]>(hql.ToString(), param);
            if (waybillDetList == null || waybillDetList.Count == 0) return null;
            else
            {
                var obj = waybillDetList[0];
                WaybillDet waybillDet = new WaybillDet()
                {
                    IpNo = obj[0].ToString(),
                    Status = obj[1].ToString(),
                    Dock = obj[2] == null ? string.Empty : obj[2].ToString(),
                    WaybillNo = obj[3] == null ? string.Empty : obj[3].ToString(),
                    DepartTime = obj[4] == null ? new System.Nullable<DateTime>() : DateTime.Parse(obj[4].ToString()),
                    ArriveTime = obj[5] == null ? new System.Nullable<DateTime>() : DateTime.Parse(obj[5].ToString()),
                    CreateUser = obj[6] == null ? string.Empty : obj[6].ToString(),
                    CreateUserNm = (obj[7] == null ? string.Empty : obj[7].ToString()) + (obj[8] == null ? string.Empty : obj[8].ToString()),
                    PartyFrom = obj[9] == null ? string.Empty : obj[9].ToString(),
                    PartyFromDesc = obj[10] == null ? string.Empty : obj[10].ToString(),
                    PartyTo = obj[11] == null ? string.Empty : obj[11].ToString(),
                    PartyToDesc = obj[12] == null ? string.Empty : obj[12].ToString(),
                    ShipFrom = obj[13] == null ? string.Empty : obj[13].ToString(),
                    ShipFromDesc = obj[14] == null ? string.Empty : obj[14].ToString(),
                    ShipTo = obj[15] == null ? string.Empty : obj[15].ToString(),
                    ShipToDesc = obj[16] == null ? string.Empty : obj[16].ToString(),
                    PalletQty = obj[17] == null ? 0 : decimal.Parse(obj[17].ToString())
                };
                return waybillDet;
            }
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<WaybillDet> GetWaybillDet(string waybillNo)
        {
            DetachedCriteria criteria = DetachedCriteria.For(typeof(WaybillDet));
            if (!string.IsNullOrEmpty(waybillNo))
            {
                criteria.Add(Expression.Eq("WaybillNo", waybillNo));
            }
            criteria.AddOrder(Order.Asc("WaybillNo"));
            criteria.AddOrder(Order.Asc("Seq"));
            return criteriaMgrE.FindAll<WaybillDet>(criteria);
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class WaybillDetMgrE : com.Sconit.TMS.Service.Impl.WaybillDetMgr, IWaybillDetMgrE
    {
    }
}

#endregion Extend Class