using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.Persistence;
using com.Sconit.Service.Ext.Criteria;
using NHibernate.Expression;
using com.Sconit.TMS.Entity;
using System.Linq;
using com.Sconit.Service.Ext.Hql;
using com.Sconit.Entity.Exception;
using com.Sconit.ISI.Service.Util;
using com.Sconit.TMS.Service.Util;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class PlaceDetMgr : PlaceDetBaseMgr, IPlaceDetMgr
    {
        public ICriteriaMgrE criteriaMgrE { get; set; }
        public IHqlMgrE hqlMgrE { get; set; }

        #region Customized Methods

        [Transaction(TransactionMode.Unspecified)]
        public IList<PlaceDet> GetPlaceDets(string waybillNo)
        {
            return GetPlaceDets(waybillNo, string.Empty);
        }
        [Transaction(TransactionMode.Unspecified)]
        public IList<PlaceDet> GetPlaceDets(string waybillNo, string shipTo)
        {
            DetachedCriteria criteria = DetachedCriteria.For(typeof(PlaceDet));
            criteria.Add(Expression.Eq("WaybillNo", waybillNo));
            if (!string.IsNullOrEmpty(shipTo))
            {
                criteria.Add(Expression.Eq("ShipTo", shipTo));
            }
            return this.criteriaMgrE.FindAll<PlaceDet>(criteria);

        }
        [Transaction(TransactionMode.Unspecified)]
        public PlaceDet LoadPlaceDet(string waybillNo, string shipFrom, string shipTo)
        {
            return LoadPlaceDet(waybillNo, shipFrom, shipTo, true);
        }

        [Transaction(TransactionMode.Unspecified)]
        public PlaceDet LoadPlaceDet(string waybillNo, string shipFrom, string shipTo, bool repeatedly)
        {
            DetachedCriteria criteria = DetachedCriteria.For(typeof(PlaceDet));
            if (!string.IsNullOrEmpty(waybillNo))
            {
                criteria.Add(Expression.Eq("WaybillNo", waybillNo));
            }
            if (repeatedly)
            {
                criteria.Add(Expression.Or(Expression.And(Expression.Eq("ShipFrom", shipFrom), Expression.Eq("ShipTo", shipTo)), Expression.And(Expression.Eq("ShipFrom", shipTo), Expression.Eq("ShipTo", shipFrom))));
            }
            else
            {
                criteria.Add(Expression.Eq("ShipFrom", shipFrom));
                criteria.Add(Expression.Eq("ShipTo", shipTo));
            }
            var placeDetList = this.criteriaMgrE.FindAll<PlaceDet>(criteria);
            if (placeDetList != null && placeDetList.Count > 0)
            {
                if (placeDetList.Count == 1)
                {
                    return placeDetList[0];
                }
                else
                {
                    var placeDets = placeDetList.Where(p => p.ShipFrom == shipFrom).ToList();
                    if (placeDetList == null || placeDets.Count == 0)
                    {
                        return placeDetList[0];
                    }
                    else
                    {
                        return placeDets[0];
                    }
                }
            }
            return null;
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<PlaceDet> GetPlaceDetList(string waybillNo, IList<string> placeList, DateTime effDate, string userCode, string userName)
        {
            StringBuilder sql = new StringBuilder();
            sql.Append("select m from Mileage m where m.IsActive=1 ");
            sql.Append(" and ( ");
            for (int i = 0; i < placeList.Count - 1; i++)
            {
                var place = placeList[i];
                if (i != 0)
                {
                    sql.Append(" or ");
                }
                sql.Append(" ((m.ShipFrom ='" + place + "' and m.ShipTo ='" + placeList[i + 1] + "' ) or (m.ShipFrom ='" + placeList[i + 1] + "' and m.ShipTo ='" + place + "' )) ");
            }
            sql.Append(" ) ");

            IList<Mileage> mileageList = this.hqlMgrE.FindAll<Mileage>(sql.ToString());

            //—È÷§
            if (mileageList == null || mileageList.Count == 0)
            {
                throw new BusinessErrorException("TMS.Waybill.NotfoundMileage");
            }

            IList<PlaceDet> placeDetList = new List<PlaceDet>();

            for (int i = 0; i < placeList.Count - 1; i++)
            {
                PlaceDet placeDet = new PlaceDet();
                var mList = mileageList.Where(m => m.ShipFrom == placeList[i] && m.ShipTo == placeList[i + 1]).ToList();

                if (mList != null && mList.Count > 0)
                {
                    placeDet.ShipFrom = mList[0].ShipFrom;
                    placeDet.ShipFromDesc = mList[0].ShipFromDesc;
                    placeDet.ShipTo = mList[0].ShipTo;
                    placeDet.ShipToDesc = mList[0].ShipToDesc;
                    placeDet.WaybillNo = waybillNo;
                    placeDet.Seq = (i + 1) * 10;
                    placeDet.Km = mList[0].Km;
                    placeDet.Remark = mList[0].Desc;
                    placeDet.LastModifyDate = effDate;
                    placeDet.LastModifyUser = userCode;
                    placeDet.LastModifyUserNm = userName;
                    placeDetList.Add(placeDet);
                }
                else
                {
                    mList = mileageList.Where(m => m.ShipTo == placeList[i] && m.ShipFrom == placeList[i + 1]).ToList();

                    if (mList != null && mList.Count > 0)
                    {
                        placeDet.ShipFrom = mList[0].ShipTo;
                        placeDet.ShipFromDesc = mList[0].ShipToDesc;
                        placeDet.ShipTo = mList[0].ShipFrom;
                        placeDet.ShipToDesc = mList[0].ShipFromDesc;
                        placeDet.WaybillNo = waybillNo;
                        placeDet.Seq = (i + 1) * 10;
                        placeDet.Km = mList[0].Km;
                        placeDet.Remark = mList[0].Desc;
                        placeDet.LastModifyDate = effDate;
                        placeDet.LastModifyUser = userCode;
                        placeDet.LastModifyUserNm = userName;
                        placeDetList.Add(placeDet);
                    }
                    else
                    {
                        throw new BusinessErrorException("TMS.Waybill.NotFoundToReturnMileageData", placeList[i], placeList[i + 1]);
                    }
                }
            }

            return placeDetList;

        }
        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class PlaceDetMgrE : com.Sconit.TMS.Service.Impl.PlaceDetMgr, IPlaceDetMgrE
    {
    }
}

#endregion Extend Class