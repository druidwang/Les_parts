using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using com.Sconit.Entity.Exception;
using com.Sconit.Utility;
using Telerik.Web.Mvc;
using com.Sconit.Web.Models.SearchModels.INV;
using com.Sconit.Web.Models;
using com.Sconit.Entity.INV;
using com.Sconit.Entity.VIEW;
using com.Sconit.Entity.SCM;
using com.Sconit.Service;
using com.Sconit.Entity.MD;
using com.Sconit.Entity.ORD;
using com.Sconit.PrintModel.INV;
using AutoMapper;
using com.Sconit.Utility.Report;
using com.Sconit.Web.Models.SearchModels.BIL;
using com.Sconit.Entity.BIL;
using com.Sconit.Web.Models.SearchModels.SCM;
using com.Sconit.Web.Models.SearchModels.ORD;
using com.Sconit.Entity;
using com.Sconit.Entity.MRP.MD;
using System.Data.SqlClient;
using System.Data;
using com.Sconit.Entity.SYS;
using NHibernate;
using Resources.WMS;

namespace com.Sconit.Web.Controllers.INV
{
    public class DeliveryBarCodeController : WebAppBaseController
    {

        private static string selectCountStatement = "select count(*) from DeliveryBarCode as h";
        private static string selectStatement = "select h from DeliveryBarCode as h";


        #region public method
        [SconitAuthorize(Permissions = "Url_DeliveryBarCode_View")]
        public ActionResult Index()
        {
            return View();
        }

        [GridAction]
        [SconitAuthorize(Permissions = "Url_DeliveryBarCode_View")]
        public ActionResult List(GridCommand command, DeliveryBarCodeSearchModel searchModel)
        {
            SearchCacheModel searchCacheModel = this.ProcessSearchModel(command, searchModel);
            ViewBag.PageSize = base.ProcessPageSize(command.PageSize);
            return View();
        }

        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_DeliveryBarCode_View")]
        public ActionResult _AjaxList(GridCommand command, DeliveryBarCodeSearchModel searchModel)
        {
            SearchCacheModel searchCacheModel = this.ProcessSearchModel(command, searchModel);
            ViewBag.PageSize = base.ProcessPageSize(command.PageSize);
            return View();
        }


        [SconitAuthorize(Permissions = "Url_DeliveryBarCode_View")]
        public ActionResult New()
        {
            TempData["FlowDetailSearchModel"] = null;
            return View();
        }

        #endregion

        #region private method
        private SearchStatementModel PrepareSearchStatement(GridCommand command, DeliveryBarCodeSearchModel searchModel)
        {
            string whereStatement = string.Empty;

            IList<object> param = new List<object>();

            HqlStatementHelper.AddLikeStatement("BarCode", searchModel.BarCode, HqlStatementHelper.LikeMatchMode.Anywhere, "h", ref whereStatement, param);
            HqlStatementHelper.AddLikeStatement("CreateUserName", searchModel.CreateUserName, HqlStatementHelper.LikeMatchMode.Start, "h", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Item", searchModel.Item, "h", ref whereStatement, param);
         

            if (searchModel.StartDate != null & searchModel.EndDate != null)
            {
                HqlStatementHelper.AddBetweenStatement("CreateDate", searchModel.StartDate, searchModel.EndDate, "h", ref whereStatement, param);
            }
            else if (searchModel.StartDate != null & searchModel.EndDate == null)
            {
                HqlStatementHelper.AddGeStatement("CreateDate", searchModel.StartDate, "h", ref whereStatement, param);
            }
            else if (searchModel.StartDate == null & searchModel.EndDate != null)
            {
                HqlStatementHelper.AddLeStatement("CreateDate", searchModel.EndDate, "h", ref whereStatement, param);
            }

           


            string sortingStatement = HqlStatementHelper.GetSortingStatement(command.SortDescriptors);
            if (command.SortDescriptors.Count == 0)
            {
                sortingStatement = " order by CreateDate desc";
            }
            SearchStatementModel searchStatementModel = new SearchStatementModel();
            searchStatementModel.SelectCountStatement = selectCountStatement;
            searchStatementModel.SelectStatement = selectStatement;
            searchStatementModel.WhereStatement = whereStatement;
            searchStatementModel.SortingStatement = sortingStatement;
            searchStatementModel.Parameters = param.ToArray<object>();

            return searchStatementModel;
        }


   
        #endregion

        #region private





        #endregion

    }
}
