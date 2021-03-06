﻿/// <summary>
/// Summary description 
/// </summary>
namespace com.Sconit.Web.Controllers.ORD
{
    #region reference
    using System.Collections;
    using System.Collections.Generic;
    using System.Linq;
    using System.Web.Mvc;
    using System.Web.Routing;
    using System.Web.Security;
    using com.Sconit.Entity.ORD;
    using com.Sconit.Entity.SYS;
    using com.Sconit.Service;
    using com.Sconit.Web.Models;
    using com.Sconit.Web.Models.SearchModels.ORD;
    using com.Sconit.Utility;
    using Telerik.Web.Mvc;
    using com.Sconit.Service.Impl;
    using com.Sconit.Entity.Exception;
    using com.Sconit.Utility.Report;
    using com.Sconit.PrintModel.ORD;
    using AutoMapper;
    using System.Text;
    using System;
    using System.ComponentModel;

    #endregion

    /// <summary>
    /// This controller response to control the Address.
    /// </summary>
    /// 


    public class ProductionReceiptController : WebAppBaseController
    {
        #region Properties
        /// <summary>
        /// Gets or sets the this.GeneMgr which main consider the ProcurementGoodsReceipt security 
        /// </summary>
        //public IGenericMgr genericMgr { get; set; }

        //public IReceiptMgr receiptMgr { get; set; }

        //public IReportGen reportGen { get; set; }
        #endregion

        /// <summary>
        /// hql 
        /// </summary>
        private static string selectCountStatement = "select count(*) from ReceiptMaster as r";

        /// <summary>
        /// hql 
        /// </summary>
        private static string selectStatement = "select r from ReceiptMaster as r";

        //public IGenericMgr genericMgr { get; set; }
        #region public actions
        /// <summary>
        /// Index action for ProcurementGoodsReceipt controller
        /// </summary>
        /// <returns>Index view</returns>
        [SconitAuthorize(Permissions = "Url_ProductionReceipt_View")]
        public ActionResult Index()
        {
            return View();
        }
        [SconitAuthorize(Permissions = "Url_ProductionReceipt_Detail")]
        public ActionResult DetailIndex()
        {
            return View();
        }

        /// <summary>
        /// List action
        /// </summary>
        /// <param name="command">Telerik GridCommand</param>
        /// <param name="searchModel"> ReceiptMaster Search model</param>
        /// <returns>return the result view</returns>
        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_ProductionReceipt_View")]
        public ActionResult List(GridCommand command, ReceiptMasterSearchModel searchModel)
        {
            SearchCacheModel searchCacheModel = this.ProcessSearchModel(command, searchModel);
            if (this.CheckSearchModelIsNull(searchCacheModel.SearchObject))
            {
                TempData["_AjaxMessage"] = "";
            }
            else
            {
                SaveWarningMessage(Resources.SYS.ErrorMessage.Errors_NoConditions);
            }
            if (searchCacheModel.isBack == true)
            {
                ViewBag.Page = searchCacheModel.Command.Page == 0 ? 1 : searchCacheModel.Command.Page;
            }
            ViewBag.PageSize = base.ProcessPageSize(command.PageSize);
            ViewBag.OrderSubType = ((ReceiptMasterSearchModel)searchCacheModel.SearchObject).OrderSubType;
            return View();
        }
        [GridAction]
        [SconitAuthorize(Permissions = "Url_ProductionReceipt_Detail")]
        public ActionResult DetailList(GridCommand command, ReceiptMasterSearchModel searchModel)
        {
            SearchCacheModel searchCacheModel = this.ProcessSearchModel(command, searchModel);
            if (this.CheckSearchModelIsNull(searchCacheModel.SearchObject))
            {
                TempData["_AjaxMessage"] = "";
            }
            else
            {
                SaveWarningMessage(Resources.SYS.ErrorMessage.Errors_NoConditions);
            }
            ViewBag.PageSize = base.ProcessPageSize(command.PageSize);
            return View();
        }
        [SconitAuthorize(Permissions = "Url_ProductionReceipt_Detail")]
        [GridAction(EnableCustomBinding = true)]
        public ActionResult _AjaxRecDetList(GridCommand command, ReceiptMasterSearchModel searchModel)
        {
            if (!this.CheckSearchModelIsNull(searchModel))
            {
                return PartialView(new GridModel(new List<ReceiptDetail>()));
            }
            string whereStatement = " ";
            //string whereStatement = " where  i.Type = " + (int)com.Sconit.CodeMaster.OrderSubType.Normal + "";
            ProcedureSearchStatementModel procedureSearchStatementModel = PrepareSearchDetailStatement(command, searchModel, whereStatement);
            return PartialView(GetAjaxPageDataProcedure<ReceiptDetail>(procedureSearchStatementModel, command));
        }
        #region  Export details
        [SconitAuthorize(Permissions = "Url_ProductionReceipt_Detail")]
        [GridAction(EnableCustomBinding = true)]
        public void ExportXLS(ReceiptMasterSearchModel searchModel)
        {
            int value = Convert.ToInt32(base.systemMgr.GetEntityPreferenceValue(EntityPreference.CodeEnum.MaxRowSizeOnPage));
            GridCommand command = new GridCommand();
            command.Page = 1;
            command.PageSize = !this.CheckSearchModelIsNull(searchModel) ? 0 : value;
            string whereStatement = null;
            ProcedureSearchStatementModel procedureSearchStatementModel = PrepareSearchDetailStatement(command, searchModel, whereStatement);
            var ReceiptDetailLists = GetAjaxPageDataProcedure<ReceiptDetail>(procedureSearchStatementModel, command);
            List<ReceiptDetail> ReceiptDetailList = ReceiptDetailLists.Data.ToList();
            ExportToXLS<ReceiptDetail>("DailsOfReceiptMaster.xls", ReceiptDetailList);
        }
        #endregion
        /// <summary>
        ///  AjaxList action
        /// </summary>
        /// <param name="command">Telerik GridCommand</param>
        /// <param name="searchModel"> ReceiptMaster Search Model</param>
        /// <returns>return the result action</returns>
        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_ProductionReceipt_View")]
        public ActionResult _AjaxList(GridCommand command, ReceiptMasterSearchModel searchModel)
        {
            this.GetCommand(ref command, searchModel);
            if (!this.CheckSearchModelIsNull(searchModel))
            {
                return PartialView(new GridModel(new List<ReceiptMaster>()));
            }

            string whereStatement =" ";
            ProcedureSearchStatementModel procedureSearchStatementModel = this.PrepareProcedureSearchStatement(command, searchModel, whereStatement);
            return PartialView(GetAjaxPageDataProcedure<ReceiptMaster>(procedureSearchStatementModel, command));
        }

        [SconitAuthorize(Permissions = "Url_ProductionReceipt_View")]
        public ActionResult Edit(string receiptNo)
        {
            if (string.IsNullOrEmpty(receiptNo))
            {
                return HttpNotFound();
            }
            else
            {
                ViewBag.ReceiptNo = receiptNo;
                ReceiptMaster rm = this.genericMgr.FindById<ReceiptMaster>(receiptNo);
                return View(rm);
            }
        }

        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_ProductionReceipt_View")]
        public ActionResult _ReceiptDetailList(string receiptNo)
        {
            string hql = "select r from ReceiptDetail as r where r.ReceiptNo = ?";
            IList<ReceiptDetail> receiptDetailList = genericMgr.FindAll<ReceiptDetail>(hql, receiptNo);
            foreach (var receiptDetail in receiptDetailList)
            {
                receiptDetail.ReceiptLocationDetails = this.genericMgr.FindAll<ReceiptLocationDetail>
                    ("from ReceiptLocationDetail where ReceiptDetailId =? ", receiptDetail.Id);
            }
            return PartialView(receiptDetailList);
        }

        [SconitAuthorize(Permissions = "Url_ProductionReceipt_Cancel")]
        public ActionResult Cancel(string id, string cancelReason)
        {
            try
            {
                ReceiptMaster ReceiptMaster = this.genericMgr.FindById<ReceiptMaster>(id);
                ReceiptMaster.CancelReason = cancelReason;
                receiptMgr.CancelReceipt(ReceiptMaster);
                SaveSuccessMessage(Resources.EXT.ControllerLan.Con_ReceiveOrderCancelledSuccessfully);
            }
            catch (BusinessException ex)
            {
                SaveErrorMessage(ex.GetMessages()[0].GetMessageString());
            }
            return RedirectToAction("Edit", new { receiptNo = id });
        }

        [GridAction(EnableCustomBinding = true)]
        public ActionResult _ResultHierarchyAjax(string id)
        {
            string hql = "select r from ReceiptLocationDetail as r where r.ReceiptDetailId = ?";
            IList<ReceiptLocationDetail> ReceiptLocationDetail = genericMgr.FindAll<ReceiptLocationDetail>(hql, id);
            return PartialView(new GridModel(ReceiptLocationDetail));
        }

        #region 打印导出
        public void SaveToClient(string receiptNo)
        {
            ReceiptMaster receiptMaster = queryMgr.FindById<ReceiptMaster>(receiptNo);
            IList<ReceiptDetail> receiptDetail = queryMgr.FindAll<ReceiptDetail>("select rd from ReceiptDetail as rd where rd.ReceiptNo=?", receiptNo);
            foreach (var receiptDet in receiptDetail)
            {
                var receiptlocationCount = genericMgr.FindAll<ReceiptLocationDetail>
                    ("from ReceiptLocationDetail as o where o.ReceiptDetailId = ?", receiptDet.Id)
                    .Where(o => !string.IsNullOrWhiteSpace(o.HuId))
                    .Count();

                if (receiptlocationCount == 0)
                {
                    receiptDet.BoxQty = (int)Math.Ceiling(receiptDet.ReceivedQty / (receiptDet.UnitCount > 0 ? receiptDet.UnitCount : 1));
                }
                else
                {
                    receiptDet.BoxQty = receiptlocationCount;
                }
            }
            receiptMaster.ReceiptDetails = receiptDetail;
            PrintReceiptMaster printReceiptMaster = Mapper.Map<ReceiptMaster, PrintReceiptMaster>(receiptMaster);
            IList<object> data = new List<object>();
            data.Add(printReceiptMaster);
            data.Add(printReceiptMaster.ReceiptDetails);
            reportGen.WriteToClient(printReceiptMaster.ReceiptTemplate, data, printReceiptMaster.ReceiptNo+ ".xls");

        }

        public string Print(string receiptNo)
        {
            ReceiptMaster receiptMaster = queryMgr.FindById<ReceiptMaster>(receiptNo);
            IList<ReceiptDetail> receiptDetail = queryMgr.FindAll<ReceiptDetail>("select rd from ReceiptDetail as rd where rd.ReceiptNo=?", receiptNo);
            foreach (var receiptDet in receiptDetail)
            {
                var receiptlocationCount = genericMgr.FindAll<ReceiptLocationDetail>
                    ("from ReceiptLocationDetail as o where o.ReceiptDetailId = ?", receiptDet.Id)
                    .Where(o => !string.IsNullOrWhiteSpace(o.HuId))
                    .Count();

                if (receiptlocationCount == 0)
                {
                    receiptDet.BoxQty = (int)Math.Ceiling(receiptDet.ReceivedQty / (receiptDet.UnitCount > 0 ? receiptDet.UnitCount : 1));
                }
                else
                {
                    receiptDet.BoxQty = receiptlocationCount;
                }
            }
            receiptMaster.ReceiptDetails = receiptDetail;
            PrintReceiptMaster printReceiptMaster = Mapper.Map<ReceiptMaster, PrintReceiptMaster>(receiptMaster);
            IList<object> data = new List<object>();
            data.Add(printReceiptMaster);
            data.Add(printReceiptMaster.ReceiptDetails);
            return reportGen.WriteToFile(printReceiptMaster.ReceiptTemplate, data);
        }
        #endregion

        #endregion

        private ProcedureSearchStatementModel PrepareProcedureSearchStatement(GridCommand command, ReceiptMasterSearchModel searchModel, string whereStatement)
        {
            List<ProcedureParameter> paraList = new List<ProcedureParameter>();
            List<ProcedureParameter> pageParaList = new List<ProcedureParameter>();
            paraList.Add(new ProcedureParameter { Parameter = searchModel.ReceiptNo, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.IpNo, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.Status, Type = NHibernate.NHibernateUtil.Int16 });
            paraList.Add(new ProcedureParameter
            {
                Parameter = (int)com.Sconit.CodeMaster.OrderType.Production,
                Type = NHibernate.NHibernateUtil.String
            });

            paraList.Add(new ProcedureParameter { Parameter = searchModel.OrderSubType, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.IpDetailType, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.PartyFrom, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.PartyTo, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.StartDate, Type = NHibernate.NHibernateUtil.DateTime });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.EndDate, Type = NHibernate.NHibernateUtil.DateTime });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.Dock, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.Item, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.ExternalReceiptNo, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.ManufactureParty, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.Flow, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = false, Type = NHibernate.NHibernateUtil.Boolean });
            paraList.Add(new ProcedureParameter { Parameter = CurrentUser.Id, Type = NHibernate.NHibernateUtil.Int32 });
            paraList.Add(new ProcedureParameter { Parameter = whereStatement, Type = NHibernate.NHibernateUtil.String });


            if (command.SortDescriptors.Count > 0)
            {
                if (command.SortDescriptors[0].Member == "ReceiptMasterStatusDescription")
                {
                    command.SortDescriptors[0].Member = "Status";
                }
            }

            pageParaList.Add(new ProcedureParameter { Parameter = command.SortDescriptors.Count > 0 ? command.SortDescriptors[0].Member : null, Type = NHibernate.NHibernateUtil.String });
            pageParaList.Add(new ProcedureParameter { Parameter = command.SortDescriptors.Count > 0 ? (command.SortDescriptors[0].SortDirection == ListSortDirection.Descending ? "desc" : "asc") : "asc", Type = NHibernate.NHibernateUtil.String });
            pageParaList.Add(new ProcedureParameter { Parameter = command.PageSize, Type = NHibernate.NHibernateUtil.Int32 });
            pageParaList.Add(new ProcedureParameter { Parameter = command.Page, Type = NHibernate.NHibernateUtil.Int32 });

            var procedureSearchStatementModel = new ProcedureSearchStatementModel();
            procedureSearchStatementModel.Parameters = paraList;
            procedureSearchStatementModel.PageParameters = pageParaList;
            procedureSearchStatementModel.CountProcedure = "USP_Search_RecMstrCount";
            procedureSearchStatementModel.SelectProcedure = "USP_Search_RecMstr";

            return procedureSearchStatementModel;
        }
        
        private ProcedureSearchStatementModel PrepareSearchDetailStatement(GridCommand command, ReceiptMasterSearchModel searchModel, string whereStatement)
        {

            List<ProcedureParameter> paraList = new List<ProcedureParameter>();
            List<ProcedureParameter> pageParaList = new List<ProcedureParameter>();
            paraList.Add(new ProcedureParameter { Parameter = searchModel.ReceiptNo, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.IpNo, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.OrderNo, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.Status, Type = NHibernate.NHibernateUtil.Int16 });
            paraList.Add(new ProcedureParameter
            {
                Parameter = (int)com.Sconit.CodeMaster.OrderType.Production,
                Type = NHibernate.NHibernateUtil.String
            });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.OrderSubType, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.IpDetailType, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.PartyFrom, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.PartyTo, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.StartDate, Type = NHibernate.NHibernateUtil.DateTime });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.EndDate, Type = NHibernate.NHibernateUtil.DateTime });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.Dock, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.Item, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.ExternalReceiptNo, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.ManufactureParty, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = searchModel.Flow, Type = NHibernate.NHibernateUtil.String });
            paraList.Add(new ProcedureParameter { Parameter = false, Type = NHibernate.NHibernateUtil.Int64 });
            paraList.Add(new ProcedureParameter { Parameter = CurrentUser.Id, Type = NHibernate.NHibernateUtil.Int32 });
            paraList.Add(new ProcedureParameter { Parameter = whereStatement, Type = NHibernate.NHibernateUtil.String });


            if (command.SortDescriptors.Count > 0)
            {
                if (command.SortDescriptors[0].Member == "StatusDescription")
                {
                    command.SortDescriptors[0].Member = "Status";
                }
            }
            pageParaList.Add(new ProcedureParameter { Parameter = command.SortDescriptors.Count > 0 ? command.SortDescriptors[0].Member : null, Type = NHibernate.NHibernateUtil.String });
            pageParaList.Add(new ProcedureParameter { Parameter = command.SortDescriptors.Count > 0 ? (command.SortDescriptors[0].SortDirection == ListSortDirection.Descending ? "desc" : "asc") : "asc", Type = NHibernate.NHibernateUtil.String });
            pageParaList.Add(new ProcedureParameter { Parameter = command.PageSize, Type = NHibernate.NHibernateUtil.Int32 });
            pageParaList.Add(new ProcedureParameter { Parameter = command.Page, Type = NHibernate.NHibernateUtil.Int32 });

            var procedureSearchStatementModel = new ProcedureSearchStatementModel();
            procedureSearchStatementModel.Parameters = paraList;
            procedureSearchStatementModel.PageParameters = pageParaList;
            procedureSearchStatementModel.CountProcedure = "USP_Search_RecDetCount";
            procedureSearchStatementModel.SelectProcedure = "USP_Search_RecDet";

            return procedureSearchStatementModel;
        }
        #region  Export master search
        [SconitAuthorize(Permissions = "Url_ProductionReceipt_View")]
        [GridAction(EnableCustomBinding = true)]
        public void ExportMstr(ReceiptMasterSearchModel searchModel)
        {
            int value = Convert.ToInt32(base.systemMgr.GetEntityPreferenceValue(EntityPreference.CodeEnum.MaxRowSizeOnPage));
            GridCommand command = new GridCommand();
            command.Page = 1;
            command.PageSize = !this.CheckSearchModelIsNull(searchModel) ? 0 : value;
            if (!this.CheckSearchModelIsNull(searchModel))
            {
                return;
            }

            string whereStatement = " ";
            ProcedureSearchStatementModel procedureSearchStatementModel = this.PrepareProcedureSearchStatement(command, searchModel, whereStatement);
            ExportToXLS<ReceiptMaster>("ProductionReceiptOrderMaster.xls", GetAjaxPageDataProcedure<ReceiptMaster>(procedureSearchStatementModel, command).Data.ToList());
        }
        #endregion
    }
}
