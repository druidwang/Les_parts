using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Castle.Services.Transaction;
using com.Sconit.Persistence;
using NHibernate.Expression;
using com.Sconit.Entity.MasterData;
using com.Sconit.Service.Ext.Criteria;
using com.Sconit.TMS.Entity;
using System.Linq;

//TODO: Add other using statements here.

namespace com.Sconit.TMS.Service.Impl
{
    [Transactional]
    public class PlaceMgr : PlaceBaseMgr, IPlaceMgr
    {
        private static IList<Place> cachedAllPlace;
        public ICriteriaMgrE criteriaMgrE { get; set; }

        #region Customized Methods
        [Transaction(TransactionMode.Unspecified)]
        public IList<Place> GetCacheAllPlace(string place)
        {
            var placeList = GetCacheAllPlace();
            if (cachedAllPlace == null)
            {
                return cachedAllPlace;
            }
            else
            {
                return cachedAllPlace.Where(p => p.Code != place).ToList();
            }
        }

        [Transaction(TransactionMode.Unspecified)]
        public IList<Place> GetCacheAllPlace()
        {
            if (cachedAllPlace == null)
            {
                cachedAllPlace = this.GetAllPlace();
            }
            else
            {
                //检查Place大小是否发生变化
                DetachedCriteria criteria = DetachedCriteria.For(typeof(Place));
                criteria.SetProjection(Projections.ProjectionList().Add(Projections.Count("Code")));
                IList<int> count = this.criteriaMgrE.FindAll<int>(criteria);

                if (count[0] != cachedAllPlace.Count)
                {
                    cachedAllPlace = GetAllPlace();
                }
            }

            return cachedAllPlace;
        }

        [Transaction(TransactionMode.Unspecified)]
        public bool ExistsCode(string code)
        {
            if (this.LoadPlace(code) != null)
            {
                return true;
            }

            return false;
        }

        [Transaction(TransactionMode.Unspecified)]
        public bool ExistsPlace(string country, string province, string city, string district, string road)
        {
            return ExistsPlace(string.Empty, country, province, city, district, road);
        }

        [Transaction(TransactionMode.Unspecified)]
        public bool ExistsPlace(string code, string country, string province, string city, string district, string road)
        {
            DetachedCriteria criteria = DetachedCriteria.For(typeof(Place)).SetProjection(Projections.CountDistinct("Code"));
            criteria.Add(Expression.Eq("Country", country));
            criteria.Add(Expression.Eq("Province", province));
            criteria.Add(Expression.Eq("City", city));
            criteria.Add(Expression.Eq("District", district));
            criteria.Add(Expression.Eq("Road", road));
            if (!string.IsNullOrEmpty(code))
            {
                criteria.Add(Expression.Not(Expression.Eq("Code", code)));
            }

            IList<int> count = this.criteriaMgrE.FindAll<int>(criteria);
            if (count != null && count.Count > 0 && count[0] > 0)
            {
                return true;
            }

            return false;
        }

        #endregion Customized Methods
    }
}


#region Extend Class

namespace com.Sconit.TMS.Service.Ext.Impl
{
    [Transactional]
    public partial class PlaceMgrE : com.Sconit.TMS.Service.Impl.PlaceMgr, IPlaceMgrE
    {
    }
}

#endregion Extend Class