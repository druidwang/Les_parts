
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

    public class RepackTaskController : WebAppBaseController
    {
        #region 翻箱任务
      
        private static string selectCountStatement = "select count(*) from RepackTask as p";

        private static string selectStatement = "select p from RepackTask as p";

        public IRepackTaskMgr repackTaskMgr { get; set; }

        #region 查看
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

      
        #endregion

        #region 分派
        [SconitAuthorize(Permissions = "Url_RepackTask_Assign")]
        public ActionResult Assign()
        {
            return View();
        }

        [SconitAuthorize(Permissions = "Url_RepackTask_Assign")]
        public ActionResult _RepackTaskList(string pickGroupCode)
        {

            ViewBag.pickGroupCode = pickGroupCode;

            return PartialView();
        }

        [GridAction]
        [SconitAuthorize(Permissions = "Url_RepackTask_Assign")]
        public ActionResult _SelectAssignBatchEditing(string pickGroupCode)
        {
            IList<RepackTask> pickTaskList = new List<RepackTask>();

            if (!string.IsNullOrEmpty(pickGroupCode))
            {
                string repackGroupSql = "select r from PickRule as r where r.PickGroupCode = ?";
                IList<PickRule> pickRuleList = genericMgr.FindAll<PickRule>(repackGroupSql, pickGroupCode);

                if (pickRuleList != null && pickRuleList.Count > 0)
                {
                    string pickRuleSql = string.Empty;
                    IList<object> param = new List<object>();

                    foreach (PickRule r in pickRuleList)
                    {
                        if (string.IsNullOrEmpty(pickRuleSql))
                        {
                            pickRuleSql += "select p from RepackTask as p where p.RepackUserId is null and p.Location in (?";
                            param.Add(r.Location);
                        }
                        else
                        {
                            pickRuleSql += ",?";
                            param.Add(r.Location);
                        }
                    }

                    if (!string.IsNullOrEmpty(pickRuleSql))
                    {
                        pickRuleSql += ")";
                    }

                    pickTaskList = genericMgr.FindAll<RepackTask>(pickRuleSql, param.ToList());
                }




            }
            return View(new GridModel(pickTaskList));
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [SconitAuthorize(Permissions = "Url_RepackTask_Assign")]
        public ActionResult AssignRepackTask(String checkedRepackTasks, String assignUser)
        {
            try
            {

                IList<RepackTask> repackTaskList = new List<RepackTask>();
                if (!string.IsNullOrEmpty(checkedRepackTasks))
                {

                    string[] idArray = checkedRepackTasks.Split(',');


                    for (int i = 0; i < idArray.Count(); i++)
                    {

                        RepackTask rt = genericMgr.FindById<RepackTask>(idArray[i]);

                        repackTaskList.Add(rt);

                    }
                }
                repackTaskMgr.AssignRepackTask(repackTaskList, assignUser);
                SaveSuccessMessage(Resources.WMS.RepackTask.RepackTask_Assigned);
                object obj = new { SuccessMessage = string.Format(Resources.WMS.RepackTask.RepackTask_Assigned, checkedRepackTasks), SuccessData = checkedRepackTasks };
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

        #region 翻包
        [SconitAuthorize(Permissions = "Url_RepackTask_Repack")]
        public ActionResult RepackIndex()
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
        [SconitAuthorize(Permissions = "Url_RepackTask_Repack")]
        public ActionResult RepackList(GridCommand command, RepackTaskSearchModel searchModel)
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
        [SconitAuthorize(Permissions = "Url_RepackTask_Repack")]
        public ActionResult _RepackAjaxList(GridCommand command, RepackTaskSearchModel searchModel)
        {
            SearchStatementModel searchStatementModel = PrepareRepackSearchStatement(command, searchModel);
            return PartialView(GetAjaxPageData<RepackTask>(searchStatementModel, command));
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Id"></param>
        /// <returns></returns>
        [HttpGet]
        [SconitAuthorize(Permissions = "Url_RepackTask_Repack")]
        public ActionResult RepackEdit(string id)
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


        #endregion


        #region private method
        private SearchStatementModel PrepareSearchStatement(GridCommand command, RepackTaskSearchModel searchModel)
        {
            string whereStatement = string.Empty;
            IList<object> param = new List<object>();
            HqlStatementHelper.AddEqStatement("RepackUserId", searchModel.RepackUser, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Location", searchModel.Location, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Item", searchModel.Item, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("IsActive", searchModel.IsActive, "p", ref whereStatement, param);

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

        private SearchStatementModel PrepareAssignSearchStatement(GridCommand command, RepackTaskSearchModel searchModel)
        {
            string whereStatement = " where p.RepackUserId is null "; 
            IList<object> param = new List<object>();
            HqlStatementHelper.AddEqStatement("Location", searchModel.Location, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Item", searchModel.Item, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("IsActive", searchModel.IsActive, "p", ref whereStatement, param);

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

        private SearchStatementModel PrepareRepackSearchStatement(GridCommand command, RepackTaskSearchModel searchModel)
        {
            string whereStatement = string.Empty;
            IList<object> param = new List<object>();
         
            HqlStatementHelper.AddEqStatement("Location", searchModel.Location, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Item", searchModel.Item, "p", ref whereStatement, param);

            //默认只能选自己的有效的
            HqlStatementHelper.AddEqStatement("RepackUserId", searchModel.RepackUser, "p", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("IsActive", true, "p", ref whereStatement, param);

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
