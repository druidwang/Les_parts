﻿using System;
using System.Collections.Generic;
using System.Linq;
using com.Sconit.Service.SI.MES;
using com.Sconit.Utility;
using Castle.Services.Transaction;
using com.Sconit.Entity.SI.SAP;
using com.Sconit.Entity;
using com.Sconit.Entity.SI.MES;
using Newtonsoft.Json;

namespace com.Sconit.Service.SI.MES.Impl
{
    public class MESServicesMgrImpl : com.Sconit.Service.SI.Impl.BaseMgr, IMESServicesMgr
    {
        private static log4net.ILog log = log4net.LogManager.GetLogger("DebugLog");

        public string CreateHu(string CustomerCode, string CustomerName, string LotNo, string Item, string ItemDesc, string ManufactureDate, string Manufacturer, string OrderNo, string Uom, decimal UC, decimal Qty, string CreateUser, string CreateDate, string Printer, string HuId)
        {
            log.InfoFormat("调用创建条码方法{0}，{1}，{2}，{3}开始", CustomerCode, LotNo, Item, HuId);
            //throw new NotImplementedException();
            var hu = string.Empty;
            hu = huMgr.CreateHu(CustomerCode, CustomerName, LotNo, Item, ItemDesc, ManufactureDate, Manufacturer, OrderNo, Uom, UC, Qty, CreateUser, CreateDate, Printer, HuId).HuId;
            log.InfoFormat("调用创建条码方法{0}，{1}，{2}，{3}结束", CustomerCode, LotNo, Item, HuId);
            return hu;
        }


        public string CreatePallet(List<string> BoxNos, string BoxCount, string Printer, string CreateUser, string CreateDate, string PalletId)
        {
            log.InfoFormat("调用创建托盘方法{0}，{1}，{2}，{3}开始", BoxNos.FirstOrDefault(), BoxCount, Printer, PalletId);
            var kp = string.Empty;
            kp = huMgr.CreatePallet(BoxNos, BoxCount, Printer, CreateUser, CreateDate, PalletId);
            log.InfoFormat("调用创建托盘方法{0}，{1}，{2}，{3}结束", BoxNos.FirstOrDefault(), BoxCount, Printer, PalletId);
            return kp;
        }

    

        public Entity.SI.MES.InventoryResponse  GetInventory(Entity.SI.MES.InventoryRequest request)
        {
            try
            {
                var response = new Entity.SI.MES.InventoryResponse();
                response.RequestId = request.RequestId;
                if (string.IsNullOrEmpty(request.RequestId))
                {
                    throw new Exception("请输入请求参数RequestId");
                }
                if (string.IsNullOrEmpty(request.Data.MaterialCode))
                {
                    throw new Exception("请输入请求参数MaterialCode");
                }
                var requestData = this.genericMgr.FindAll<MES_Interface_Inventory>("from MES_Interface_Inventory m where RequestId=? and Status=0", request.RequestId, 0, 200);
                if (requestData == null || requestData.Count == 0)
                {
                    this.genericMgr.FindAllWithNamedQuery<object[]>("USP_MES_GetInventory", new object[] { request.RequestId, request.Data.MaterialCode, request.Data.WarehouseCode, request.Data.BarCode, request.Data.BatchNo }).FirstOrDefault();
                    requestData = this.genericMgr.FindAll<MES_Interface_Inventory>("from MES_Interface_Inventory m where RequestId=? and Status=0 order by Id", request.RequestId, 0, 200);
                    if (requestData.Count < 200)
                    {
                        response.IsEnd = true;
                    }
                    response.Inventorys = requestData.ToList();
                }
                else
                {
                    if (requestData.Count < 200)
                    {
                        response.IsEnd = true;
                    }
                    response.Inventorys = requestData.ToList();
                }
                this.genericMgr.FindAllWithNativeSql("update top(200) a set Status=1 from MES_Interface_Inventory a where RequestId=? and Status=0", request.RequestId);
                return response;
            }
            catch (Exception)
            {
                
                throw;
            }
            
        }


        #region 导出事务信息给MES
        public static object ExportMaterialIOLock = new object();
        public List<ErrorMessage> ExportMaterialIO()
        {
            lock (ExportMaterialIOLock)
            {
                var errorMessageList = new List<ErrorMessage>();

                try
                {
                    //获取状态是0的数据按时间排序
                    var result = this.genericMgr.FindAll<MES_Interface_MaterialIO>("from MES_Interface_MaterialIO where Status=0");

                    //根据批次调用接口发送数据
                    WSMes.WSMes mesSeviceProxy = new WSMes.WSMes();
                    
                    //STMES0001.ZfunStmes0001 input = new STMES0001.ZfunStmes0001();
                    //STMES0001.ZWS_STMES0001 sapSeviceProxy = new STMES0001.ZWS_STMES0001();
                    //sapSeviceProxy.Credentials = new NetworkCredential(this.SAPService_UserName, this.SAPService_Password);
                    //sapSeviceProxy.Timeout = int.Parse(this.SAPService_TimeOut);
                    //sapSeviceProxy.Url = GetServiceUrl(sapSeviceProxy.Url);
                    var requestId = Guid.NewGuid().ToString().Replace("-", "");
                    List<string> uniqueCodeList = result.Select(r => r.UniqueCode).Distinct().ToList();
                    //List<MES_Interface_MaterialIO> sendRows = new List<MES_Interface_MaterialIO>();
                    DateTime? transStartDate = DateTime.Now;
                    DateTime? dataFromDate = null;
                    DateTime? dataToDate = null;
                    foreach (var uniqueCode in uniqueCodeList)
                    {
                        var request = new MaterialIORequest();
                        request.requester = "WMS";
                        request.request_id = requestId;
                        request.request_date = DateTime.Now;
                        request.data = result.Where(r => r.UniqueCode == uniqueCode).ToList();
                        var jsonRequest = JsonConvert.SerializeObject(request);

                        try
                        {
                            var response = mesSeviceProxy.MATERIAL_IO_BOUND(jsonRequest);
                            //input.ItData = sendRows.ToArray();
                            //sapSeviceProxy.ZfunStmes0001(input);

                            this.genericMgr.FindAllWithNativeSql("update MES_Interface_MaterialIO set status=1 where UniqueCode=?", uniqueCode);
                            this.SaveTransferLog(uniqueCode, "SUCCESS", "MES_Interface_MaterialIO", BusinessConstants.MESMATERIALIO_SYSTEMCODE, 1, 200, transStartDate, dataFromDate, dataToDate);
                        }
                        catch (Exception ex)
                        {
                            string logMessage = "传输业务数据给MES时失败,批次号为：" + uniqueCode + "，失败信息：" + ex.Message;
                            errorMessageList.Add(new ErrorMessage
                            {
                                Template = NVelocityTemplateRepository.TemplateEnum.ExportBusDataToSAPErrorTemplate,
                                Message = logMessage
                            });
                            this.SaveTransferLog(uniqueCode, logMessage, "STMES0001", BusinessConstants.MESMATERIALIO_SYSTEMCODE, 2, 200, transStartDate, dataFromDate, dataToDate);
                        }
                    }
                }
                catch (Exception ex)
                {
                    string logMessage = "传输业务数据给SAP出错。";
                    errorMessageList.Add(new ErrorMessage
                    {
                        Template = NVelocityTemplateRepository.TemplateEnum.ExportBusDataToSAPErrorTemplate,
                        Exception = ex,
                        Message = logMessage
                    });
                }

                this.SendErrorMessage(errorMessageList);
                return errorMessageList;
            }
        }
        #endregion

        #region transmit all business data
        public static object TransBusinessOrderDataLock = new object();
        public List<ErrorMessage> TransBusinessOrderData()
        {
            lock (TransBusinessOrderDataLock)
            {
                var errorMessageList = new List<ErrorMessage>();
                DateTime? transStartDate = DateTime.Now;
                DateTime? dataFromDate = null;
                DateTime? dataToDate = null;
                try
                {
                    //DateTime currDate = DateTime.Now;
                    var messages = new List<ErrorMessage>();

                    messages.AddRange(ExportMaterialIO());

                    //记录成功日志
                    this.SaveTransferLog("TransBusinessData", "SUCCESS", "TransBusinessData", "TransBusinessData", 1, 0, transStartDate, dataFromDate, dataToDate);
                }
                catch (Exception ex)
                {
                    string logMessage = "业务接口数据传输失败，失败的时间点为:" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                    errorMessageList.Add(new ErrorMessage
                    {
                        Template = NVelocityTemplateRepository.TemplateEnum.ExportBusDataToSAPErrorTemplate,
                        Exception = ex,
                        Message = logMessage
                    });
                }
                this.SendErrorMessage(errorMessageList);
                return errorMessageList;
            }


        }
        #endregion
        #region Export and transmit all business data
        public static object GenBusinessOrderDataLock = new object();
        [Transaction(TransactionMode.Requires)]
        public List<ErrorMessage> GenBusinessOrderData(DateTime currDate)
        {
            SAPTransferTimeControl timeControl = new SAPTransferTimeControl();
            lock (GenBusinessOrderDataLock)
            {
                var errorMessageList = new List<ErrorMessage>();
                string dBName = genericMgr.FindAllWithNativeSql<string>("Select DB_NAME()").FirstOrDefault();
                DateTime? transStartDate = DateTime.Now;
                DateTime? dataFromDate = currDate;
                DateTime? dataToDate = DateTime.Now;
                try
                {
                    //DateTime currDate = DateTime.Now;
                    var timeContrlCode = BusinessConstants.MESMATERIALIO_SYSTEMCODE;
                    timeControl = this.genericMgr.FindById<Entity.SI.SAP.SAPTransferTimeControl>(timeContrlCode);
                    dataFromDate = timeControl.CurrTransDate;
                    var batchNo = Guid.NewGuid().ToString().Replace("-", "");
                    if (!timeControl.CurrTransDate.HasValue)
                    {
                        return errorMessageList;
                    }
                    if (timeControl.CurrTransDate > currDate)
                    {
                        return errorMessageList;
                    }
                    this.genericMgr.FindAllWithNamedQuery<object[]>("USP_MES_MaterialIO", new object[] { Guid.NewGuid().ToString().Replace("-", ""), timeControl.CurrTransDate, currDate }).FirstOrDefault();
                    //data transmission
                    var messages = new List<ErrorMessage>();
                    //记录成功日志
                    timeControl.LastTransDate = timeControl.CurrTransDate;
                    timeControl.CurrTransDate = currDate;
                    this.genericMgr.Update(timeControl);
                    this.SaveTransferLog(timeContrlCode, "SUCCESS", timeContrlCode, timeContrlCode, 1, 0, transStartDate, dataFromDate, dataToDate);

                }
                catch (Exception ex)
                {
                    string logMessage = "业务接口数据生成失，失败的时间段为:" + timeControl.CurrTransDate.Value.ToString("yyyy-MM-dd HH:mm:ss") + " 到 " + currDate.ToString("yyyy-MM-dd HH:mm:ss");
                    errorMessageList.Add(new ErrorMessage
                    {
                        Template = NVelocityTemplateRepository.TemplateEnum.ExportBusDataToSAPErrorTemplate,
                        Exception = ex,
                        Message = logMessage
                    });
                    this.SendErrorMessage(errorMessageList);
                    throw ex;

                }
                this.SendErrorMessage(errorMessageList);
                return errorMessageList;
            }


        }
        #endregion
    }
}	