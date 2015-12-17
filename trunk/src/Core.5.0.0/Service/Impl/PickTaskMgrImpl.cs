using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.WMS;
using com.Sconit.Entity.INV;
using com.Sconit.Entity.Exception;
using com.Sconit.Entity;
using com.Sconit.Entity.ACC;
using System.Data;
using System.Data.SqlClient;

namespace com.Sconit.Service.Impl
{
    public class PickTaskMgrImpl : BaseMgr, IPickTaskMgr
    {
        public IGenericMgr genericMgr { get; set; }

        public IList<PickTask> CreatePickTask(IDictionary<int, decimal> shipPlanIdAndQtyDic)
        {
            throw new NotImplementedException();
        }

        public void PorcessPick(Dictionary<int, List<Hu>> pickResults)
        {
            User user = SecurityContextHolder.Get();
            if (pickResults == null || pickResults.Count == 0)
            {
                throw new BusinessException("拣货结果不能为空。");
            }
            DataTable pickResultTable = new DataTable();
            pickResultTable.Columns.Add(new DataColumn("PickTaskId", Type.GetType("System.Int32")));
            pickResultTable.Columns.Add(new DataColumn("HuId", Type.GetType("System.Int32")));
            pickResultTable.Columns.Add(new DataColumn("HuQty", Type.GetType("System.Decimal")));
            foreach (var pickResult in pickResults)
	        {
		        foreach (var hu in pickResult.Value)
	            {
		            DataRow row = pickResultTable.NewRow();
                    row[0] = pickResult.Key;
                    row[1] = hu.HuId;
                    row[2] = hu.Qty;
	            }
	        }
            SqlParameter[] paras = new SqlParameter[3];
            paras[0] = new SqlParameter("@UserId", SqlDbType.Int);
            paras[0].Value  = user.Id;
            paras[1] = new SqlParameter("@UserName", SqlDbType.VarChar);
            paras[1].Value=user.FullName;
            paras[1] = new SqlParameter("@PickResult", SqlDbType.Structured);
            paras[1].Value=pickResultTable;

            this.genericMgr.ExecuteStoredProcedure("USP_Busi_WMS_ProcessPickResult", paras);
        }
    }
}
