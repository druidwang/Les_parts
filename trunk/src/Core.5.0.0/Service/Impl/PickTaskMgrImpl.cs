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

        public void CreatePickTask(IDictionary<int, decimal> shipPlanIdAndQtyDic)
        {
            User user = SecurityContextHolder.Get();
            SqlParameter[] paras = new SqlParameter[3];
            DataTable createPickTaskTable = new DataTable();
            createPickTaskTable.Columns.Add("Id", typeof(Int32));
            createPickTaskTable.Columns.Add("PickQty", typeof(decimal));
            foreach (var i in shipPlanIdAndQtyDic)
            {
                DataRow row = createPickTaskTable.NewRow();
                row[0] = i.Key;
                row[1] = i.Value;
                createPickTaskTable.Rows.Add(row);
            }
            paras[0] = new SqlParameter("@CreatePickTaskTable", SqlDbType.Structured);
            paras[0].Value = createPickTaskTable;
            paras[1] = new SqlParameter("@CreateUserId", SqlDbType.Int);
            paras[1].Value = user.Id;
            paras[2] = new SqlParameter("@CreateUserNm", SqlDbType.VarChar);
            paras[2].Value = user.FullName;

            try
            {
                DataSet msgs = this.genericMgr.GetDatasetByStoredProcedure("USP_WMS_CreatePickTask", paras);

                //SqlDataReader reader = this.genericMgr.GetDatasetBySql("exec USP_WMS_CreatePickTask", paras); 

                if (msgs != null && msgs.Tables != null && msgs.Tables[0] != null
                    && msgs.Tables[0].Rows != null && msgs.Tables[0].Rows.Count > 0)
                {
                    foreach (DataRow msg in msgs.Tables[0].Rows)
                    {
                        if ((int)msg[0] == 0)
                        {
                            MessageHolder.AddInfoMessage((string)msg[1]);
                        }
                        else if ((int)msg[0] == 1)
                        {
                            MessageHolder.AddWarningMessage((string)msg[1]);
                        }
                        else
                        {
                            MessageHolder.AddErrorMessage((string)msg[1]);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                if (ex.InnerException != null)
                {
                    if (ex.InnerException.InnerException != null)
                    {
                        MessageHolder.AddErrorMessage(ex.InnerException.InnerException.Message);
                    }
                    else
                    {
                        MessageHolder.AddErrorMessage(ex.InnerException.Message);
                    }
                }
                else
                {
                    MessageHolder.AddErrorMessage(ex.Message);
                }
            }
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
            paras[0].Value = user.Id;
            paras[1] = new SqlParameter("@UserName", SqlDbType.VarChar);
            paras[1].Value = user.FullName;
            paras[1] = new SqlParameter("@PickResult", SqlDbType.Structured);
            paras[1].Value = pickResultTable;

            this.genericMgr.ExecuteStoredProcedure("USP_Busi_WMS_ProcessPickResult", paras);
        }
    }
}
