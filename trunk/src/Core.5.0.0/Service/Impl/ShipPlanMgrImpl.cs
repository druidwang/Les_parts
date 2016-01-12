using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.ORD;
using com.Sconit.Entity.Exception;
using com.Sconit.Entity.WMS;
using System.Data.SqlClient;
using System.Data;
using com.Sconit.Entity;
using com.Sconit.Entity.ACC;
using Castle.Services.Transaction;

namespace com.Sconit.Service.Impl
{
    [Transactional]
    public class ShipPlanMgrImpl : IShipPlanMgr
    {
        public IGenericMgr genericMgr { get; set; }
        public IOrderMgr orderMgr { get; set; }
        public ITransportMgr transportMgr { get; set; }

        public void CreateShipPlan(string orderNo)
        {
            User user = SecurityContextHolder.Get();
            genericMgr.ExecuteUpdateWithNativeQuery("exec USP_WMS_CreateShipPlan ?, ?, ?", new object[] { orderNo, user.Id, user.FullName });
        }

        public void CancelShipPlan(string orderNo)
        {
            throw new NotImplementedException();
        }

        public void AssignShipPlan(IList<ShipPlan> shipPlanList, string assignUser)
        {
            if (shipPlanList != null && shipPlanList.Count > 0)
            {
                User lastModifyUser = SecurityContextHolder.Get();
                User user = genericMgr.FindById<User>(Convert.ToInt32(assignUser));
                foreach (ShipPlan p in shipPlanList)
                {
                    p.ShipUserId = user.Id;
                    p.ShipUserName = user.FullName;
                    p.LastModifyDate = DateTime.Now;
                    p.LastModifyUserId = lastModifyUser.Id;
                    p.LastModifyUserName = lastModifyUser.FullName;
                    genericMgr.Update(p);
                }

            }
        }

        [Transaction(TransactionMode.Requires)]
        public void ProcessShipPlanResult4Hu(string transportOrderNo, IList<string> huIdList, DateTime? effDate)
        {
            DataSet ds = null;
            #region 处理发运计划
            User user = SecurityContextHolder.Get();
            SqlParameter[] paras = new SqlParameter[3];
            DataTable shipResultTable = new DataTable();
            shipResultTable.Columns.Add("HuId", typeof(string));
            foreach (var hu in huIdList)
            {
                DataRow row = shipResultTable.NewRow();
                row[0] = hu;
                shipResultTable.Rows.Add(row);
            }
            paras[0] = new SqlParameter("@ShipResultTable", SqlDbType.Structured);
            paras[0].Value = shipResultTable;
            paras[1] = new SqlParameter("@CreateUserId", SqlDbType.Int);
            paras[1].Value = user.Id;
            paras[2] = new SqlParameter("@CreateUserNm", SqlDbType.VarChar);
            paras[2].Value = user.FullName;

            try
            {
                ds = this.genericMgr.GetDatasetByStoredProcedure("USP_WMS_ProcessShipResult4Hu", paras);

                if (ds != null && ds.Tables != null && ds.Tables[0] != null
                    && ds.Tables[0].Rows != null && ds.Tables[0].Rows.Count > 0)
                {
                    foreach (DataRow msg in ds.Tables[0].Rows)
                    {
                        if (msg[0].ToString() == "0")
                        {
                            MessageHolder.AddInfoMessage((string)msg[1]);
                        }
                        else if (msg[0].ToString() == "1")
                        {
                            MessageHolder.AddWarningMessage((string)msg[1]);
                        }
                        else
                        {
                            MessageHolder.AddErrorMessage((string)msg[1]);
                        }
                    }

                    return;
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

                return;
            }
            #endregion

            #region 创建ASN并添加到运输单中
            if (ds != null && ds.Tables != null && ds.Tables[1] != null
                   && ds.Tables[1].Rows != null && ds.Tables[1].Rows.Count > 0)
            {
                IList<object> orderDetailIdList = new List<object>();
                foreach (DataRow hu in ds.Tables[1].Rows)
                {
                    if (!orderDetailIdList.Contains(hu[3]))
                    {
                        orderDetailIdList.Add(hu[3]);
                    }
                }

                IList<OrderDetail> orderDetailList = genericMgr.FindAllIn<OrderDetail>("from OrderDetail where Id in(?", orderDetailIdList);
                IDictionary<string, IList<OrderDetail>> flowDic = new Dictionary<string, IList<OrderDetail>>();
                foreach (DataRow hu in ds.Tables[1].Rows)
                {
                    OrderDetail orderDetail = orderDetailList.Where(od => od.Id == (int)hu[3]).Single();
                    OrderDetailInput orderDetailInput = new OrderDetailInput();
                    orderDetailInput.HuId = (string)hu[0];
                    orderDetailInput.LotNo = (string)hu[1];
                    orderDetailInput.ShipQty = (decimal)hu[2];
                    orderDetail.AddOrderDetailInput(orderDetailInput);

                    if (!flowDic.ContainsKey((string)hu[4]))
                    {
                        IList<OrderDetail> flowOrderDetailList = new List<OrderDetail>();
                        flowOrderDetailList.Add(orderDetail);
                        flowDic.Add((string)hu[4], flowOrderDetailList);
                    }
                    else
                    {
                        IList<OrderDetail> flowOrderDetailList = flowDic[(string)hu[4]];
                        if (!flowOrderDetailList.Contains(orderDetail))
                        {
                            flowOrderDetailList.Add(orderDetail);
                        }
                    }
                }

                if (!effDate.HasValue)
                {
                    effDate = DateTime.Now;
                }

                IList<string> ipNoList = new List<string>();
                foreach (var flow in flowDic)
                {
                    IpMaster ipMaster = orderMgr.ShipOrder(flow.Value, effDate.Value);
                    ipNoList.Add(ipMaster.IpNo);
                }

                if (!string.IsNullOrWhiteSpace(transportOrderNo))
                {
                    transportMgr.AddTransportOrderDetail(transportOrderNo, ipNoList);
                }
            }
            else
            {
                throw new TechnicalException("返回的条码信息为空。");
            }
            #endregion
        }
    }
}