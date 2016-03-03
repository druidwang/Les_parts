/// <summary>
/// Summary description for FacilityMasterController
/// </summary>
namespace com.Sconit.Web.Controllers.FMS
{
    #region reference
    using System.Collections;
    using System.Collections.Generic;
    using System.Linq;
    using System.Web.Mvc;
    using System.Web.Routing;
    using System.Web.Security;
    using com.Sconit.Entity.MD;
    using com.Sconit.Entity.SYS;
    using com.Sconit.Service;
    using com.Sconit.Web.Models;
    using com.Sconit.Web.Models.SearchModels.MD;
    using com.Sconit.Utility;
    using Telerik.Web.Mvc;
    using com.Sconit.Web.Models.SearchModels.FMS;
    using com.Sconit.Entity.FMS;
    using com.Sconit.Entity.ACC;
    #endregion

    /// <summary>
    /// This controller response to control the FacilityMaster.
    /// </summary>
    public class FacilityMasterController : WebAppBaseController
    {
        #region Properties
        /// <summary>
        /// Gets or sets the this.GeneMgr which main consider the facilityMaster security 
        /// </summary>
        //public IGenericMgr genericMgr { get; set; }
        public IFacilityMgr facilityMgr { get; set; }
        #endregion

        /// <summary>
        /// hql to get count of the facilityMaster
        /// </summary>
        private static string selectCountStatement = "select count(*) from FacilityMaster as f";

        /// <summary>
        /// hql to get all of the facilityMaster
        /// </summary>
        private static string selectStatement = "select f from FacilityMaster as f";

        /// <summary>
        /// hql to get count of the facilityMaster by facilityMaster's code
        /// </summary>
        private static string duiplicateVerifyStatement = @"select count(*) from FacilityMaster as f where f.Code = ?";

        #region public actions
        /// <summary>
        /// Index action for FacilityMaster controller
        /// </summary>
        /// <returns>Index view</returns>
        [SconitAuthorize(Permissions = "Url_FacilityMaster_View")]
        public ActionResult Index()
        {
            return View();
        }

        /// <summary>
        /// List action
        /// </summary>
        /// <param name="command">Telerik GridCommand</param>
        /// <param name="searchModel">FacilityMaster Search model</param>
        /// <returns>return the result view</returns>
        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_FacilityMaster_View")]
        public ActionResult List(GridCommand command, FacilityMasterSearchModel searchModel)
        {
            SearchCacheModel searchCacheModel = this.ProcessSearchModel(command, searchModel);
            if (searchCacheModel.isBack == true)
            {
                ViewBag.Page = searchCacheModel.Command.Page == 0 ? 1 : searchCacheModel.Command.Page;
            }
            ViewBag.PageSize = base.ProcessPageSize(command.PageSize);
            return View();
        }

        /// <summary>
        ///  AjaxList action
        /// </summary>
        /// <param name="command">Telerik GridCommand</param>
        /// <param name="searchModel">FacilityMaster Search Model</param>
        /// <returns>return the result action</returns>
        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_FacilityMaster_View")]
        public ActionResult _AjaxList(GridCommand command, FacilityMasterSearchModel searchModel)
        {
            this.GetCommand(ref command, searchModel);
            SearchStatementModel searchStatementModel = this.PrepareSearchStatement(command, searchModel);
            return PartialView(GetAjaxPageData<FacilityMaster>(searchStatementModel, command));
        }

        /// <summary>
        /// New action
        /// </summary>
        /// <returns>New view</returns>
        [SconitAuthorize(Permissions = "Url_FacilityMaster_Edit")]
        public ActionResult New()
        {
            return View();
        }

        /// <summary>
        /// New action
        /// </summary>
        /// <param name="facilityMaster">FacilityMaster Model</param>
        /// <returns>return the result view</returns>
        [HttpPost]
        [SconitAuthorize(Permissions = "Url_FacilityMaster_Edit")]
        public ActionResult New(FacilityMaster facilityMaster)
        {
            if (ModelState.IsValid)
            {
                facilityMgr.CreateFacilityMaster(facilityMaster);
                SaveSuccessMessage(Resources.FMS.FacilityMaster.FacilityMaster_Added);
                return RedirectToAction("Edit/" + facilityMaster.FCID);
            }

            return View(facilityMaster);
        }

        [HttpGet]
        [SconitAuthorize(Permissions = "Url_FacilityMaster_View")]
        public ActionResult _EditList(string id)
        {
            if (string.IsNullOrEmpty(id))
            {
                return HttpNotFound();
            }
            else
            {
                return View("_EditList", string.Empty, id);
            }
        }

        /// <summary>
        /// Edit view
        /// </summary>
        /// <param name="id">facilityMaster id for edit</param>
        /// <returns>return the result view</returns>
        [HttpGet]
        [SconitAuthorize(Permissions = "Url_FacilityMaster_View")]
        public ActionResult Edit(string id)
        {
            if (string.IsNullOrEmpty(id))
            {
                return HttpNotFound();
            }
            else
            {
                FacilityMaster facilityMaster = this.genericMgr.FindById<FacilityMaster>(id);
                return View(facilityMaster);
            }
        }

        /// <summary>
        /// Edit view
        /// </summary>
        /// <param name="facilityMaster">FacilityMaster Model</param>
        /// <returns>return the result view</returns>
        [SconitAuthorize(Permissions = "Url_FacilityMaster_Edit")]
        public ActionResult Edit(FacilityMaster facilityMaster)
        {
            if (ModelState.IsValid)
            {
                facilityMaster.CurrChargePersonName = genericMgr.FindById<User>(facilityMaster.CurrChargePersonId).FullName;
                this.genericMgr.UpdateWithTrim(facilityMaster);
                SaveSuccessMessage(Resources.FMS.FacilityMaster.FacilityMaster_Updated);
            }

            return View(facilityMaster);
        }

        /// <summary>
        /// Delete action
        /// </summary>
        /// <param name="id">facilityMaster id for delete</param>
        /// <returns>return to List action</returns>
        [SconitAuthorize(Permissions = "Url_FacilityMaster_Delete")]
        public ActionResult Delete(string id)
        {
            if (string.IsNullOrEmpty(id))
            {
                return HttpNotFound();
            }
            else
            {
                this.genericMgr.DeleteById<FacilityMaster>(id);
                SaveSuccessMessage(Resources.FMS.FacilityMaster.FacilityMaster_Deleted);
                return RedirectToAction("List");
            }
        }
        #endregion

        /// <summary>
        /// Search Statement
        /// </summary>
        /// <param name="command">Telerik GridCommand</param>
        /// <param name="searchModel">FacilityMaster Search Model</param>
        /// <returns>return facilityMaster search model</returns>
        private SearchStatementModel PrepareSearchStatement(GridCommand command, FacilityMasterSearchModel searchModel)
        {
            string whereStatement = string.Empty;

            IList<object> param = new List<object>();

            HqlStatementHelper.AddLikeStatement("FCID", searchModel.FCID, HqlStatementHelper.LikeMatchMode.Start, "f", ref whereStatement, param);
            HqlStatementHelper.AddLikeStatement("Name", searchModel.Name, HqlStatementHelper.LikeMatchMode.Anywhere, "f", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Status", searchModel.Status, "f", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("ChargePerson", searchModel.ChargePerson, "f", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("ChargeSite", searchModel.ChargeSite, "f", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("ChargeOrganization", searchModel.ChargeOrganization, "f", ref whereStatement, param);
            HqlStatementHelper.AddLikeStatement("RefenceCode", searchModel.RefenceCode, HqlStatementHelper.LikeMatchMode.Anywhere, "f", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("MaintainGroup", searchModel.MaintainGroup, "f", ref whereStatement, param);
            HqlStatementHelper.AddLikeStatement("OwnerDescription", searchModel.OwnerDescription, HqlStatementHelper.LikeMatchMode.Anywhere, "f", ref whereStatement, param);


            string sortingStatement = HqlStatementHelper.GetSortingStatement(command.SortDescriptors);

            SearchStatementModel searchStatementModel = new SearchStatementModel();
            searchStatementModel.SelectCountStatement = selectCountStatement;
            searchStatementModel.SelectStatement = selectStatement;
            searchStatementModel.WhereStatement = whereStatement;
            searchStatementModel.SortingStatement = sortingStatement;
            searchStatementModel.Parameters = param.ToArray<object>();

            return searchStatementModel;
        }
    }
}
