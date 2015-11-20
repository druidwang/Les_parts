
namespace com.Sconit.Web.Controllers.TMS
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
    using com.Sconit.Web.Models.SearchModels.MD;
    using com.Sconit.Entity.TMS;
    using com.Sconit.Utility;
    using com.Sconit.Entity.WMS;

    public class PickWindowTimeController : WebAppBaseController
    {
        #region 承运商
      
        private static string selectCountStatement = "select count(*) from PickWindowTime as c";

        private static string selectCountRegionStatement = "select count(*) from Region as r where r.Code = ?";

        private static string selectCountSupplierStatement = "select count(*) from Supplier as s where s.Code = ?";

        private static string selectCountCustomerStatement = "select count(*) from Customer as c where c.Code = ?";

        private static string selectStatement = "select c from PickWindowTime as c";

        private static string selectCountPickWindowTimeStatement = "select count(*) from PickWindowTime as s where s.Code = ?";


        [SconitAuthorize(Permissions = "Url_PickWindowTime_View")]
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
        [SconitAuthorize(Permissions = "Url_PickWindowTime_View")]
        public ActionResult List(GridCommand command, PartySearchModel searchModel)
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
        [SconitAuthorize(Permissions = "Url_PickWindowTime_View")]
        public ActionResult _AjaxList(GridCommand command, PartySearchModel searchModel)
        {
            SearchStatementModel searchStatementModel = PrepareSearchStatement(command, searchModel);
            return PartialView(GetAjaxPageData<PickWindowTime>(searchStatementModel, command));
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [SconitAuthorize(Permissions = "Url_PickWindowTime_Edit")]
        public ActionResult New()
        {
            return View();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="region"></param>
        /// <returns></returns>
        [HttpPost]
        [SconitAuthorize(Permissions = "Url_PickWindowTime_Edit")]
        public ActionResult New(PickWindowTime PickWindowTime)
        {
            if (ModelState.IsValid)
            {
                //判断描述不能重复
                if (base.genericMgr.FindAll<long>(selectCountPickWindowTimeStatement, new object[] { PickWindowTime.PickScheduleNo,PickWindowTime.ShiftCode })[0] > 0)
                {
                    base.SaveErrorMessage(Resources.MD.Party.Party_Supplier_Errors_Existing_Code, PickWindowTime.PickScheduleNo);
                }
              
            }
            return View(PickWindowTime);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Id"></param>
        /// <returns></returns>
        [HttpGet]
        [SconitAuthorize(Permissions = "Url_PickWindowTime_Edit")]
        public ActionResult Edit(string Id)
        {

            if (string.IsNullOrEmpty(Id))
            {
                return HttpNotFound();
            }

            return View("Edit", "", Id);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Id"></param>
        /// <returns></returns>
        [HttpGet]
        [SconitAuthorize(Permissions = "Url_PickWindowTime_Edit")]
        public ActionResult _Edit(string Id)
        {

            if (string.IsNullOrEmpty(Id))
            {
                return HttpNotFound();
            }
            else
            {
                ViewBag.PartyCode = Id;
                PickWindowTime PickWindowTime = base.genericMgr.FindById<PickWindowTime>(Id);
                return PartialView(PickWindowTime);
            }

        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="region"></param>
        /// <returns></returns>
        [HttpPost]
        [SconitAuthorize(Permissions = "Url_PickWindowTime_Edit")]
        public ActionResult _Edit(PickWindowTime PickWindowTime)
        {

            if (ModelState.IsValid)
            {
                base.genericMgr.Update(PickWindowTime);
               // SaveSuccessMessage(Resources.MD.Party.Party_PickWindowTime_Updated);
            }

            TempData["TabIndex"] = 0;
            return new RedirectToRouteResult(new RouteValueDictionary  
                                                   { 
                                                       { "action", "_Edit" }, 
                                                       { "controller", "PickWindowTime" } ,
                                                       { "Id", PickWindowTime.Id }
                                                   });
        }

        [SconitAuthorize(Permissions = "Url_PickWindowTime_Delete")]
        public ActionResult Delete(string id)
        {
            if (id == null)
            {
                return HttpNotFound();
            }
            else
            {
                base.genericMgr.DeleteById<PickWindowTime>(id);
                //SaveSuccessMessage(Resources.MD.Party.Party_PickWindowTime_Deleted);
                return RedirectToAction("List");
            }
        }
        private SearchStatementModel PrepareSearchStatement(GridCommand command, PartySearchModel searchModel)
        {
            string whereStatement = string.Empty;
            IList<object> param = new List<object>();
            HqlStatementHelper.AddLikeStatement("Code", searchModel.Code, HqlStatementHelper.LikeMatchMode.Start, "c", ref whereStatement, param);
            HqlStatementHelper.AddLikeStatement("Name", searchModel.Name, HqlStatementHelper.LikeMatchMode.Start, "c", ref whereStatement, param);
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
