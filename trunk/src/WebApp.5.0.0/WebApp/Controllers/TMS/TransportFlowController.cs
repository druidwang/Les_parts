﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using com.Sconit.Utility;
using Telerik.Web.Mvc;
using com.Sconit.Web.Models.SearchModels.TMS;
using com.Sconit.Web.Models;
using com.Sconit.Entity.TMS;
using com.Sconit.Entity.MD;

namespace com.Sconit.Web.Controllers.TMS
{
    public class TransportFlowController : WebAppBaseController
    {
        //
        // GET: /TransportFlow/
        private static string selectCountStatement = "select count(*) from TransportFlowMaster as f ";
        private static string selectStatement = "select f from TransportFlowMaster as f";

        private static string selectCountDetailStatement = "select count(*) from TransportFlowMaster as f ";
        private static string selectDetailStatement = "select f from TransportFlowMaster as f";


        //private static string userNameDuiplicateVerifyStatement = @"select count(*) from FlowMaster as u where u.Code = ?";
        [SconitAuthorize(Permissions = "Url_TransferFlow_View")]
        public ActionResult Index()
        {
            return View();
        }

        #region FlowMaster

        [GridAction]
        [SconitAuthorize(Permissions = "Url_TransportFlow_View")]
        public ActionResult List(GridCommand command, TransportFlowSearchModel searchModel)
        {
            SearchCacheModel searchCacheModel = this.ProcessSearchModel(command, searchModel);
            if (searchCacheModel.isBack == true)
            {
                ViewBag.Page = searchCacheModel.Command.Page == 0 ? 1 : searchCacheModel.Command.Page;
            }
            ViewBag.PageSize = base.ProcessPageSize(command.PageSize);
            return View();
        }

        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_TransportFlow_View")]
        public ActionResult _AjaxList(GridCommand command, TransportFlowSearchModel searchModel)
        {
            this.GetCommand(ref command, searchModel);
            SearchStatementModel searchStatementModel = PrepareSearchStatement(command, searchModel);
            return PartialView(GetAjaxPageData<TransportFlowMaster>(searchStatementModel, command));
        }

        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_TransportFlow_View")]
        public ActionResult _AjaxFlowCarrierList(GridCommand command, string id)
        {
            GridModel<TransportFlowCarrier> GridModel = new GridModel<TransportFlowCarrier>();
            GridModel.Total = (int)this.genericMgr.FindAll<long>("select count(*) from TransportFlowCarrier tf where tf.Flow=?", id)[0];
            var result = this.genericMgr.FindAll<TransportFlowCarrier>("from TransportFlowCarrier tf where tf.Flow=?", id, (command.Page - 1) * command.PageSize, command.PageSize);
            this.FillCodeDetailDescription<TransportFlowCarrier>(result);
            GridModel.Data = result;
            return PartialView(GridModel);
        }

        [GridAction]
        [SconitAuthorize(Permissions = "Url_TransportFlow_View")]
        public ActionResult _UpdateFlowCarrier(GridCommand command, TransportFlowCarrier flowCarrier)
        {
            var dbFlowCarrier = this.genericMgr.FindById<TransportFlowCarrier>(flowCarrier.Id);
            dbFlowCarrier.Carrier = flowCarrier.Carrier;
            dbFlowCarrier.CarrierName = flowCarrier.CarrierName;
            dbFlowCarrier.TransportMode = flowCarrier.TransportMode;
            dbFlowCarrier.PriceList = flowCarrier.PriceList;
            this.genericMgr.Update(dbFlowCarrier);
            GridModel<TransportFlowCarrier> GridModel = new GridModel<TransportFlowCarrier>();
            GridModel.Total = (int)this.genericMgr.FindAll<long>("select count(*) from TransportFlowCarrier tf where tf.Flow=?", dbFlowCarrier.Flow)[0];
            var result = this.genericMgr.FindAll<TransportFlowCarrier>("from TransportFlowCarrier tf where tf.Flow=?", dbFlowCarrier.Flow, (command.Page - 1) * command.PageSize, command.PageSize);
            this.FillCodeDetailDescription<TransportFlowCarrier>(result);
            GridModel.Data = result;
            return PartialView(GridModel);
        }

        [GridAction]
        [SconitAuthorize(Permissions = "Url_TransportFlow_View")]
        public ActionResult _InsertFlowCarrier(GridCommand command, TransportFlowCarrier flowCarrier)
        {
            var dbFlowCarrier = new TransportFlowCarrier();
            dbFlowCarrier.Carrier = flowCarrier.Carrier;
            dbFlowCarrier.CarrierName = flowCarrier.CarrierName;
            dbFlowCarrier.TransportMode = flowCarrier.TransportMode;
            dbFlowCarrier.PriceList = flowCarrier.PriceList;
            dbFlowCarrier.Sequence = flowCarrier.Sequence;
            this.genericMgr.Create(dbFlowCarrier);
            GridModel<TransportFlowCarrier> GridModel = new GridModel<TransportFlowCarrier>();
            GridModel.Total = (int)this.genericMgr.FindAll<long>("select count(*) from TransportFlowCarrier tf where tf.Flow=?", dbFlowCarrier.Flow)[0];
            var result = this.genericMgr.FindAll<TransportFlowCarrier>("from TransportFlowCarrier tf where tf.Flow=?", dbFlowCarrier.Flow, (command.Page - 1) * command.PageSize, command.PageSize);
            this.FillCodeDetailDescription<TransportFlowCarrier>(result);
            GridModel.Data = result;
            return PartialView(GridModel);
        }

        public string _GetCarrierName(string code)
        {
            if (!string.IsNullOrEmpty(code))
            {
                Carrier carrier = genericMgr.FindById<Carrier>(code);
                if (carrier != null)
                {
                    return carrier.Name;
                }

            }
            return null;
        }

        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_TransportFlow_View")]
        public ActionResult _AjaxFlowRouteList(GridCommand command, string flow)
        {
            GridModel<TransportFlowRoute> GridModel = new GridModel<TransportFlowRoute>();
            GridModel.Total = (int)this.genericMgr.FindAll<long>("select count(*) from TransportFlowRoute tf where tf.Flow=?", flow)[0];
            var result = this.genericMgr.FindAll<TransportFlowRoute>("from TransportFlowRoute tf where tf.Flow=?", flow, (command.Page - 1) * command.PageSize, command.PageSize);
            this.FillCodeDetailDescription<TransportFlowRoute>(result);
            GridModel.Data = result;
            return PartialView(GridModel);
        }


        [SconitAuthorize(Permissions = "Url_TransportFlow_View")]
        public ActionResult New()
        {
            return View();
        }

        [HttpPost]
        [SconitAuthorize(Permissions = "Url_TransportFlow_Edit")]
        public ActionResult New(TransportFlowMaster flow)
        {
            if (ModelState.IsValid)
            {
                if (this.genericMgr.FindAll<long>("select count(*) from TransportFlowMaster as f where f.Code = ?", flow.Code)[0] > 0)
                 {
                     base.SaveErrorMessage(Resources.SYS.ErrorMessage.Errors_Existing_Code, flow.Code);
                 }
                else
                {
                    this.genericMgr.Create(flow);
                    SaveSuccessMessage(Resources.SCM.FlowMaster.FlowMaster_Added);
                    return RedirectToAction("Edit/" + flow.Code);
                }
            }

            //    else
            //    {
            //        flow.FlowStrategy = com.Sconit.CodeMaster.FlowStrategy.Manual;
            //        flow.Type = com.Sconit.CodeMaster.OrderType.Transfer;
            //        flowMgr.CreateFlow(flow);
            //        SaveSuccessMessage(Resources.SCM.FlowMaster.FlowMaster_Added);
            //        return RedirectToAction("Edit/" + flow.Code);
            //    }
            //}
            return View(flow);
        }

        [HttpGet]
        [SconitAuthorize(Permissions = "Url_TransportFlowMaster_View")]
        public ActionResult Edit(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                return HttpNotFound();
            }
            if (TempData["SaveErrorMessage"] != null)
            {
                string errorMessage = (TempData["SaveErrorMessage"]).ToString();
                SaveErrorMessage(errorMessage);
            }
            TransportFlowMaster flow = this.genericMgr.FindById<TransportFlowMaster>(id);
            return View(flow);
        }

        [HttpGet]
        [SconitAuthorize(Permissions = "Url_TransportFlowMaster_View")]
        public ActionResult _Edit(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                return HttpNotFound();
            }
            if (TempData["SaveErrorMessage"] != null)
            {
                string errorMessage = (TempData["SaveErrorMessage"]).ToString();
                SaveErrorMessage(errorMessage);
            }
            TransportFlowMaster flow = this.genericMgr.FindById<TransportFlowMaster>(id);
            return PartialView(flow);
        }

        [HttpPost]
        [SconitAuthorize(Permissions = "Url_TransportFlowMaster_Edit")]
        public ActionResult _Edit(TransportFlowMaster flow)
        {


           
            //if (ModelState.IsValid)
            //{
               
            //   if (string.IsNullOrEmpty(flow.PartyFrom))
            //   {
            //        base.SaveErrorMessage(Resources.SYS.ErrorMessage.Errors_Common_FieldRequired, Resources.SCM.FlowMaster.FlowMaster_TransferPartyFrom);
            //    }
            //    else if (string.IsNullOrEmpty(flow.PartyTo))
            //    {
            //        base.SaveErrorMessage(Resources.SYS.ErrorMessage.Errors_Common_FieldRequired, Resources.SCM.FlowMaster.FlowMaster_TransferPartyTo);
            //    }
            //    else if (string.IsNullOrEmpty(flow.LocationFrom))
            //    {
            //        base.SaveErrorMessage(Resources.SYS.ErrorMessage.Errors_Common_FieldRequired, Resources.SCM.FlowMaster.FlowMaster_LocationFrom);
            //    }
            //    else if (string.IsNullOrEmpty(flow.LocationTo))
            //    {
            //        base.SaveErrorMessage(Resources.SYS.ErrorMessage.Errors_Common_FieldRequired, Resources.SCM.FlowMaster.FlowMaster_LocationTo);
            //    }
            //    else if (string.IsNullOrEmpty(flow.ShipFrom))
            //    {
            //        base.SaveErrorMessage(Resources.SYS.ErrorMessage.Errors_Common_FieldRequired, Resources.SCM.FlowMaster.FlowMaster_ShipFrom);
            //    }
            //    else if (string.IsNullOrEmpty(flow.ShipTo))
            //    {
            //        base.SaveErrorMessage(Resources.SYS.ErrorMessage.Errors_Common_FieldRequired, Resources.SCM.FlowMaster.FlowMaster_ShipTo);
            //    }
            //    else
            //    {
            //        flow.Type = com.Sconit.CodeMaster.OrderType.Transfer;
            //        genericMgr.UpdateWithTrim(flow);
            //        SaveSuccessMessage(Resources.SCM.FlowMaster.FlowMaster_Updated);
            //    }
            //}

            return PartialView(flow);
        }
        [SconitAuthorize(Permissions = "Url_TransportFlowMaster_Delete")]
        public ActionResult FlowDel(string id)
        {
            if (string.IsNullOrEmpty(id))
            {
                return HttpNotFound();
            }
            else
            {
                try
                {
                    flowMgr.DeleteFlow(id);
                    SaveSuccessMessage(Resources.SCM.FlowMaster.FlowMaster_Deleted);
                    return RedirectToAction("List");
                }
                catch (System.Exception ex)
                {
                    if (ex is System.NullReferenceException)
                    {
                        //SaveErrorMessage("路线已经被引用，不能删除。");
                        TempData["SaveErrorMessage"] = Resources.EXT.ControllerLan.Con_RouteHasBeenCitedCanNotBeDeleted;
                    }
                    else
                    {
                        TempData["SaveErrorMessage"] = ex.Message;
                    }
                    TempData["TabIndex"] = 0;
                    return View("Edit", string.Empty, id);
                }
            }
        }

        [SconitAuthorize(Permissions = "Url_TransferFlow_Delete")]
        public ActionResult Delete(int? id)
        {
            if (!id.HasValue)
            {
                return HttpNotFound();
            }
            else
            {
                genericMgr.DeleteById<TransportFlowMaster>(id);
                SaveSuccessMessage(Resources.ACC.User.User_Deleted);
                return RedirectToAction("List");
            }
        }

        private SearchStatementModel PrepareSearchStatement(GridCommand command, TransportFlowSearchModel searchModel)
        {
            string whereStatement = "";

            IList<object> param = new List<object>();

            HqlStatementHelper.AddLikeStatement("Code", searchModel.Flow, HqlStatementHelper.LikeMatchMode.Anywhere, "f", ref whereStatement, param);
            HqlStatementHelper.AddLikeStatement("Description", searchModel.Description, HqlStatementHelper.LikeMatchMode.Anywhere, "f", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("IsActive", searchModel.IsActive, "f", ref whereStatement, param);

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
