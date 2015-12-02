
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

    public class RepackTaskController : WebAppBaseController
    {
        #region 翻箱任务
      
        private static string selectCountStatement = "select count(*) from RepackTask as p";

        private static string selectStatement = "select p from RepackTask as p";

        [SconitAuthorize(Permissions = "Url_RepackTask_View")]
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
        [SconitAuthorize(Permissions = "Url_RepackTask_View")]
        public ActionResult List(GridCommand command, RepackTaskSearchModel searchModel)
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
        [SconitAuthorize(Permissions = "Url_RepackTask_View")]
        public ActionResult _AjaxList(GridCommand command, RepackTaskSearchModel searchModel)
        {
            SearchStatementModel searchStatementModel = PrepareSearchStatement(command, searchModel);
            return PartialView(GetAjaxPageData<RepackTask>(searchStatementModel, command));
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [SconitAuthorize(Permissions = "Url_RepackTask_Edit")]
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
        [SconitAuthorize(Permissions = "Url_RepackTask_Edit")]
        public ActionResult Edit(string id)
        {

            if (string.IsNullOrEmpty(id))
            {
                return HttpNotFound();
            }
            else
            {
                RepackTask pickSchedule = base.genericMgr.FindById<RepackTask>(id);
                return View(pickSchedule);
            }

        }

        private SearchStatementModel PrepareSearchStatement(GridCommand command, RepackTaskSearchModel searchModel)
        {
            string whereStatement = string.Empty;
            IList<object> param = new List<object>();
            HqlStatementHelper.AddEqStatement("RepackUser", searchModel.RepackUser, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Location", searchModel.Location,  "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Item", searchModel.Item, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("IsActive", searchModel.IsActive, "p", ref whereStatement, param);

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
        #endregion

      
    }
}
