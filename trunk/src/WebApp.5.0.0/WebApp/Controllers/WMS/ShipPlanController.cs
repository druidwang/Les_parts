
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

    public class ShipPlanController : WebAppBaseController
    {
        #region 发货任务
      
        private static string selectCountStatement = "select count(*) from ShipPlan as p";

        private static string selectStatement = "select p from ShipPlan as p";


        #region 查询
        [SconitAuthorize(Permissions = "Url_ShipPlan_View")]
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
        [SconitAuthorize(Permissions = "Url_ShipPlan_View")]
        public ActionResult List(GridCommand command, ShipPlanSearchModel searchModel)
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
        [SconitAuthorize(Permissions = "Url_ShipPlan_View")]
        public ActionResult _AjaxList(GridCommand command, ShipPlanSearchModel searchModel)
        {
            SearchStatementModel searchStatementModel = PrepareSearchStatement(command, searchModel);
            return PartialView(GetAjaxPageData<ShipPlan>(searchStatementModel, command));
        }

        #endregion

        #region 发货
        [SconitAuthorize(Permissions = "Url_ShipPlan_Ship")]
        public ActionResult ShipIndex()
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
        [SconitAuthorize(Permissions = "Url_ShipPlan_Ship")]
        public ActionResult ShipList(GridCommand command, ShipPlanSearchModel searchModel)
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
        [SconitAuthorize(Permissions = "Url_ShipPlan_Ship")]
        public ActionResult _AjaxShipList(GridCommand command, ShipPlanSearchModel searchModel)
        {
            SearchStatementModel searchStatementModel = PrepareShipSearchStatement(command, searchModel);
            return PartialView(GetAjaxPageData<ShipPlan>(searchStatementModel, command));
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [SconitAuthorize(Permissions = "Url_ShipPlan_Ship")]
        public ActionResult Assign(String checkedShipPlans)
        {
            try
            {
                IList<ShipPlan> shipPlanList = new List<ShipPlan>();
                if (!string.IsNullOrEmpty(checkedShipPlans))
                {
                    string[] idArray = checkedShipPlans.Split(',');
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
                object obj = new { SuccessMessage = string.Format(Resources.ORD.OrderMaster.OrderMaster_Received, checkedShipPlans), SuccessData = checkedShipPlans };
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


        private SearchStatementModel PrepareSearchStatement(GridCommand command, ShipPlanSearchModel searchModel)
        {
            string whereStatement = string.Empty;
            IList<object> param = new List<object>();
            HqlStatementHelper.AddEqStatement("OrderNo", searchModel.OrderNo, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Flow", searchModel.Flow, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("PartyFrom", searchModel.PartyFrom, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("PartyTo", searchModel.PartyTo, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Item", searchModel.Item, "p", ref whereStatement, param);

            if (searchModel.DateFrom != null)
            {
                HqlStatementHelper.AddGeStatement("CreateDate", searchModel.DateFrom, "p", ref whereStatement, param);
            }
            else if (searchModel.DateTo != null )
            {
                HqlStatementHelper.AddLeStatement("CreateDate", searchModel.DateTo, "p", ref whereStatement, param);
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

        private SearchStatementModel PrepareShipSearchStatement(GridCommand command, ShipPlanSearchModel searchModel)
        {
            string whereStatement = " where p.PickedQty > p.ShipQty "; 
            IList<object> param = new List<object>();
            HqlStatementHelper.AddEqStatement("OrderNo", searchModel.OrderNo, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Flow", searchModel.Flow, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("PartyFrom", searchModel.PartyFrom, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("PartyTo", searchModel.PartyTo, "p", ref whereStatement, param);
           

            if (searchModel.DateFrom != null)
            {
                HqlStatementHelper.AddGeStatement("CreateDate", searchModel.DateFrom, "p", ref whereStatement, param);
            }
            else if (searchModel.DateTo != null)
            {
                HqlStatementHelper.AddLeStatement("CreateDate", searchModel.DateTo, "p", ref whereStatement, param);
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

      
    }
}
