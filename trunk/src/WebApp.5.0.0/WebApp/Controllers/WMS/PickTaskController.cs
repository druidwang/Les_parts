
namespace com.Sconit.Web.Controllers.WMS
{

    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Web;
    using System.Web.Mvc;
    using System.Web.Security;
    using com.Sconit.Entity.MD;
    using com.Sconit.Entity.SYS;
    using com.Sconit.Service;
    using Telerik.Web.Mvc;
    using System.Web.Routing;
    using com.Sconit.Web.Models;
    using com.Sconit.Utility;
    using com.Sconit.Web.Models.SearchModels.WMS;
    using com.Sconit.Entity.WMS;
    using com.Sconit.Entity.Exception;
    using com.Sconit.Service.Impl;

    public class PickTaskController : WebAppBaseController
    {
        #region 拣货任务
      
        private static string selectCountStatement = "select count(*) from PickTask as p";

        private static string selectStatement = "select p from PickTask as p";

        public IPickTaskMgr pickTaskMgr { get; set; }

        #region 查询
        [SconitAuthorize(Permissions = "Url_PickTask_View")]
        public ActionResult Index()
        {
            return View();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="command"></param>
        /// <param name="searchModel"></param>
        /// <returns></returns>
        [GridAction]
        [SconitAuthorize(Permissions = "Url_PickTask_View")]
        public ActionResult List(GridCommand command, PickTaskSearchModel searchModel)
        {
           
            SearchCacheModel searchCacheModel = this.ProcessSearchModel(command, searchModel);
            ViewBag.PageSize = base.ProcessPageSize(command.PageSize);
            return View();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="command"></param>
        /// <param name="searchModel"></param>
        /// <returns></returns>
        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_PickTask_View")]
        public ActionResult _AjaxList(GridCommand command, PickTaskSearchModel searchModel)
        {
            SearchStatementModel searchStatementModel = PrepareSearchStatement(command, searchModel);
            return PartialView(GetAjaxPageData<PickTask>(searchStatementModel, command));
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [SconitAuthorize(Permissions = "Url_PickTask_Edit")]
        public ActionResult New()
        {
            return View();
        }
     
        /// <summary>
        /// 
        /// </summary>
        /// <param name="Id"></param>
        /// <returns></returns>
        [HttpGet]
        [SconitAuthorize(Permissions = "Url_PickTask_Edit")]
        public ActionResult Edit(string id)
        {

            if (string.IsNullOrEmpty(id))
            {
                return HttpNotFound();
            }
            else
            {
                PickTask pickSchedule = base.genericMgr.FindById<PickTask>(id);
                return View(pickSchedule);
            }

        }
        #endregion


    


        #region 创建

        [SconitAuthorize(Permissions = "Url_OrderMstr_Distribution_View")]
        public ActionResult _ShipPlanList(string flow, string orderNo)
        {
            ViewBag.isManualCreateDetail = false;
            ViewBag.flow = flow;
            ViewBag.orderNo = orderNo;
          
            return PartialView();
        }

        [GridAction]
        [SconitAuthorize(Permissions = "Url_OrderMstr_Distribution_View")]
        public ActionResult _SelectBatchEditing(string orderNo, string flow)
        {
            IList<ShipPlan> shipPlanList = new List<ShipPlan>();
            String sqlStatement = String.Empty;
            if (!string.IsNullOrEmpty(flow) || !string.IsNullOrEmpty(orderNo))
            {
                if (!string.IsNullOrEmpty(orderNo))
                {
                    sqlStatement = "select p from ShipPlan as p where p.OrderNo = '" + orderNo + "' ";
                }
                if (!string.IsNullOrEmpty(flow))
                {
                    if (String.IsNullOrEmpty(sqlStatement))
                    {
                        sqlStatement = "select p from ShipPlan as p where p.Flow = '" + flow + "' ";
                    }
                    else
                    {
                        sqlStatement += " and p.Flow = '" + flow + "' ";
                    }
                }
                shipPlanList = genericMgr.FindAll<ShipPlan>(sqlStatement);
            }
            return View(new GridModel(shipPlanList));
        }

        [AcceptVerbs(HttpVerbs.Post)]
        [GridAction]
        [SconitAuthorize(Permissions = "Url_PickTask_New")]
        public JsonResult Create(String checkedShipPlans)
        {
            try
            {
                IDictionary<int, decimal> shipPlanIdAndQtyDic = new Dictionary<int, decimal>();
                if (!string.IsNullOrEmpty(checkedShipPlans))
                {
                    string[] idArray = checkedShipPlans.Split(',');
                    for (int i = 0; i < idArray.Count(); i++)
                    {
                        ShipPlan sp = genericMgr.FindById<ShipPlan>(Convert.ToInt32(idArray[i]));
                        shipPlanIdAndQtyDic.Add(sp.Id, sp.ToPickQty);
                    }
                }
                pickTaskMgr.CreatePickTask(shipPlanIdAndQtyDic);
                SaveSuccessMessage(Resources.WMS.PickTask.PickTask_Created);
                object obj = new { SuccessMessage = string.Format(Resources.WMS.PickTask.PickTask_Created), SuccessData = checkedShipPlans };
                return Json(obj);

            }
            catch (BusinessException ex)
            {
                Response.TrySkipIisCustomErrors = true;
                Response.StatusCode = 500;
                Response.Write(ex.GetMessages()[0].GetMessageString());
                return Json(null);
            }
        }
        #endregion

        #region 分派
        [SconitAuthorize(Permissions = "Url_PickTask_Assign")]
        public ActionResult AssignIndex()
        {
            return View();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="command"></param>
        /// <param name="searchModel"></param>
        /// <returns></returns>
        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_PickTask_Assign")]
        public ActionResult AssignList(GridCommand command, PickTaskSearchModel searchModel)
        {
            SearchCacheModel searchCacheModel = this.ProcessSearchModel(command, searchModel);
            ViewBag.PageSize = base.ProcessPageSize(command.PageSize);
            return View();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="command"></param>
        /// <param name="searchModel"></param>
        /// <returns></returns>
        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_PickTask_Assign")]
        public ActionResult _AjaxAssignPlanList(GridCommand command, PickTaskSearchModel searchModel)
        {
            SearchStatementModel searchStatementModel = PrepareAssignSearchStatement(command, searchModel);
            return PartialView(GetAjaxPageData<PickTask>(searchStatementModel, command));
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [SconitAuthorize(Permissions = "Url_PickTask_Assign")]
        public ActionResult Assign(String checkedPickTasks,String assignUser)
        {
            try
            {
                //if (String.IsNullOrEmpty(checkedPickTasks))
                //{

                //}
                //if(String.IsNullOrEmpty(assignUser))
                //{

                //}

                IList<ShipPlan> shipPlanList = new List<ShipPlan>();
                if (!string.IsNullOrEmpty(checkedPickTasks))
                {

                    string[] idArray = checkedPickTasks.Split(',');


                    for (int i = 0; i < idArray.Count(); i++)
                    {

                        ShipPlan sp = genericMgr.FindById<ShipPlan>(Convert.ToInt32(idArray[i]));

                        shipPlanList.Add(sp);

                    }
                }
                //if (orderDetailList.Count() == 0)
                //{
                //    throw new BusinessException(Resources.EXT.ControllerLan.Con_ReceiveDetailCanNotBeEmpty);
                //}

                //orderMgr.ReceiveOrder(orderDetailList);
                object obj = new { SuccessMessage = string.Format(Resources.ORD.OrderMaster.OrderMaster_Received, checkedPickTasks), SuccessData = checkedPickTasks };
                return Json(obj);

            }
            catch (BusinessException ex)
            {
                Response.TrySkipIisCustomErrors = true;
                Response.StatusCode = 500;
                Response.Write(ex.GetMessages()[0].GetMessageString());
                return Json(null);
            }
        }
        #endregion


        #region private method
        private SearchStatementModel PrepareSearchStatement(GridCommand command, PickTaskSearchModel searchModel)
        {
            string whereStatement = string.Empty;
            IList<object> param = new List<object>();
            HqlStatementHelper.AddEqStatement("PickUser", searchModel.PickUser, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Location", searchModel.Location,  "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Item", searchModel.Item, "p", ref whereStatement, param);

            if (searchModel.DateFrom != null)
            {
                HqlStatementHelper.AddGeStatement("CreateDate", searchModel.DateFrom, "p", ref whereStatement, param);
            }
            if (searchModel.DateTo != null )
            {
                HqlStatementHelper.AddLtStatement("CreateDate", searchModel.DateTo.Value.AddDays(1), "p", ref whereStatement, param);
            }
            string sortingStatement = HqlStatementHelper.GetSortingStatement(command.SortDescriptors);
            SearchStatementModel searchStatementModel = new SearchStatementModel();
            searchStatementModel.SelectCountStatement = selectCountStatement;
            searchStatementModel.SelectStatement = selectStatement;
            searchStatementModel.WhereStatement = whereStatement;
            searchStatementModel.SortingStatement = sortingStatement;
            searchStatementModel.Parameters = param.ToArray<object>();
            return searchStatementModel;
        }

        private SearchStatementModel PrepareAssignSearchStatement(GridCommand command, PickTaskSearchModel searchModel)
        {
           
            string whereStatement = " where p.PickUserId is null "; 
            IList<object> param = new List<object>();
            HqlStatementHelper.AddEqStatement("Location", searchModel.Location, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Item", searchModel.Item, "p", ref whereStatement, param);
           

            if (searchModel.DateFrom != null)
            {
                HqlStatementHelper.AddGeStatement("CreateDate", searchModel.DateFrom, "p", ref whereStatement, param);
            }
            if (searchModel.DateTo != null)
            {
                HqlStatementHelper.AddLtStatement("CreateDate", searchModel.DateTo.Value.AddDays(1), "p", ref whereStatement, param);
            }

           
            string sortingStatement = HqlStatementHelper.GetSortingStatement(command.SortDescriptors);
            SearchStatementModel searchStatementModel = new SearchStatementModel();
            searchStatementModel.SelectCountStatement = selectCountStatement;
            searchStatementModel.SelectStatement = selectStatement;
            searchStatementModel.WhereStatement = whereStatement;
            searchStatementModel.SortingStatement = sortingStatement;
            searchStatementModel.Parameters = param.ToArray<object>();
            return searchStatementModel;
        }
        #endregion

        #endregion
    }
}
