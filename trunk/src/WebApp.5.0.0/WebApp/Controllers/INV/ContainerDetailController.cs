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

namespace com.Sconit.Web.Controllers.INV
{
    public class ContainerDetailController : WebAppBaseController
    {

        private static string selectCountStatement = "select count(*) from Hu as h";
        private static string selectStatement = "select h from Hu as h";

        private static string selectCountFlowStatement = "select count(*) from FlowDetail as h";
        private static string selectFlowStatement = "select h from FlowDetail as h";

        private static string selectIpCountStatement = "select count(*) from IpDetail as h";
        private static string selectIpStatement = "select h from IpDetail as h";

        private static string selectLocationCountStatement = "select count(*) from IpLocationDetail as h";
        private static string selectLocationStatement = "select h from IpLocationDetail as h";

        private static string selectOrderCountStatement = "select count(*) from OrderDetail as o";
        private static string selectOrderStatement = "select o from OrderDetail as o";

      
        public IHuMgr huMgr { get; set; }


        #region public method
        public ActionResult Index()
        {
            return View();
        }


        [SconitAuthorize(Permissions = "Url_ContainerDetail_View")]
        public ActionResult New()
        {
           
            return View();
        }

     
       [GridAction]
        [SconitAuthorize(Permissions = "Url_Inventory_Hu_View")]
        public ActionResult List(GridCommand command, HuSearchModel searchModel)
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
        [SconitAuthorize(Permissions = "Url_Inventory_Hu_View")]
        public ActionResult _AjaxList(GridCommand command, HuSearchModel searchModel)
        {
            TempData["HuSearchModel"] = searchModel;
            this.GetCommand(ref command, searchModel);
            SearchStatementModel searchStatementModel = PrepareSearchStatement(command, searchModel);
            var list = GetAjaxPageData<Hu>(searchStatementModel, command);
            foreach (var data in list.Data)
            {
                data.HuStatus = huMgr.GetHuStatus(data.HuId);
                data.ItemDescription = string.IsNullOrWhiteSpace(data.ReferenceItemCode) ? data.ItemDescription : data.ItemDescription + "[" + data.ReferenceItemCode + "]";
            }

            return PartialView(list);
        }

        public ActionResult HuDetail(string id, string BackUrl)
        {
            Hu hu = genericMgr.FindById<Hu>(id);
            hu.HuStatus = huMgr.GetHuStatus(id);
            FillCodeDetailDescription(hu);
            FillCodeDetailDescription(hu.HuStatus);
            if (!string.IsNullOrWhiteSpace(hu.ItemVersion))
            {
                hu.ItemVersion = hu.ItemVersion + "[" + genericMgr.FindById<ProductType>(hu.ItemVersion).Description + "]";
            }
            ViewBag.BackUrl = BackUrl;
            if (ViewBag.BackUrl == null)
            {
                ViewBag.BackUrl = "/Hu/List";
            }
            return View("HuDetail", string.Empty, hu);
        }
        [GridAction(EnableCustomBinding = true)]

        #region 打印导出
        [HttpPost]
        public void SaveToClient(string huId)
        {
            string huTemplate = this.systemMgr.GetEntityPreferenceValue(Entity.SYS.EntityPreference.CodeEnum.DefaultBarCodeTemplate);
            string[] checkedOrderArray = huId.Split(',');
            string selectStatement = string.Empty;
            IList<object> selectPartyPara = new List<object>();
            foreach (var para in checkedOrderArray)
            {
                if (selectStatement == string.Empty)
                {
                    selectStatement = "from Hu where HuId in (?";
                }
                else
                {
                    selectStatement += ",?";
                }
                selectPartyPara.Add(para);
            }
            selectStatement += ")";

            IList<Hu> huList = genericMgr.FindAll<Hu>(selectStatement, selectPartyPara.ToArray());
            foreach (var hu in huList)
            {
                if (!string.IsNullOrEmpty(hu.ManufactureParty))
                {
                    hu.ManufacturePartyDescription = queryMgr.FindById<Party>(hu.ManufactureParty).Name;
                }
                if (!string.IsNullOrWhiteSpace(hu.HuTemplate))
                {
                    huTemplate = hu.HuTemplate;
                }

                if (!string.IsNullOrWhiteSpace(hu.Direction))
                {
                    hu.Direction = this.genericMgr.FindById<HuTo>(hu.Direction).CodeDescription;
                }
            }
            IList<PrintHu> printHu = Mapper.Map<IList<Hu>, IList<PrintHu>>(huList);
            IList<object> data = new List<object>();
            data.Add(printHu);
            data.Add(CurrentUser.FullName);
            reportGen.WriteToClient(huTemplate, data, huTemplate);
        }

        [HttpPost]
        public void SaveToClientTo(string checkedOrders)
        {
            string defaultHuTemplate = this.systemMgr.GetEntityPreferenceValue(Entity.SYS.EntityPreference.CodeEnum.DefaultBarCodeTemplate);

            string[] checkedOrderArray = checkedOrders.Split(',');
            string selectStatement = string.Empty;
            IList<object> selectPartyPara = new List<object>();
            foreach (var para in checkedOrderArray)
            {
                if (selectStatement == string.Empty)
                {
                    selectStatement = "from Hu where HuId in (?";
                }
                else
                {
                    selectStatement += ",?";
                }
                selectPartyPara.Add(para);
            }
            selectStatement += ")";

            IList<Hu> huList = genericMgr.FindAll<Hu>(selectStatement, selectPartyPara.ToArray());
            foreach (var hu in huList)
            {
                if (!string.IsNullOrEmpty(hu.ManufactureParty))
                {
                    hu.ManufacturePartyDescription = queryMgr.FindById<Party>(hu.ManufactureParty).Name;
                }
                if (string.IsNullOrWhiteSpace(hu.HuTemplate))
                {
                    hu.HuTemplate = defaultHuTemplate;
                }
                if (!string.IsNullOrWhiteSpace(hu.Direction))
                {
                    hu.Direction = this.genericMgr.FindById<HuTo>(hu.Direction).CodeDescription;
                }
            }
            var huGroupList = huList.GroupBy(p => p.HuTemplate, (k, g) => new { k, g });
            foreach (var huGroup in huGroupList)
            {
                IList<PrintHu> printHuList = Mapper.Map<IList<Hu>, IList<PrintHu>>(huGroup.g.ToList());
                IList<object> data = new List<object>();
                data.Add(printHuList);
                data.Add(CurrentUser.FullName);
                reportGen.WriteToClient(huGroup.k, data, huGroup.k);
            }
        }

        public string Print(string huId)
        {
            Hu hu = queryMgr.FindById<Hu>(huId);
            if (!string.IsNullOrEmpty(hu.ManufactureParty))
            {
                hu.ManufacturePartyDescription = queryMgr.FindById<Party>(hu.ManufactureParty).Name;
            }
            if (!string.IsNullOrWhiteSpace(hu.Direction))
            {
                hu.Direction = this.genericMgr.FindById<HuTo>(hu.Direction).CodeDescription;
            }
            string huTemplate = hu.HuTemplate;
            if (string.IsNullOrWhiteSpace(huTemplate))
            {
                huTemplate = this.systemMgr.GetEntityPreferenceValue(Entity.SYS.EntityPreference.CodeEnum.DefaultBarCodeTemplate);
            }
            IList<PrintHu> huList = new List<PrintHu>();
            PrintHu printHu = Mapper.Map<Hu, PrintHu>(hu);
            huList.Add(printHu);
            IList<object> data = new List<object>();
            data.Add(huList);
            data.Add(CurrentUser.FullName);
            return reportGen.WriteToFile(huTemplate, data);
        }
        [HttpPost]
        public JsonResult CheckExportTemplate(string checkedOrders)
        {
            string[] checkedOrderArray = checkedOrders.Split(',');
            string selectStatement = string.Empty;
            List<object> huIds = new List<object>();
            foreach (var checkedOrder in checkedOrderArray)
            {
                huIds.Add(checkedOrder);
            }
            var templateCount = genericMgr.FindAllIn<Hu>("from Hu as i where i.HuId in (?", huIds).Select(o => o.HuTemplate).Distinct().Count();
            var message = "OK";
            if (templateCount > 1)
            {
                message = string.Format(Resources.EXT.ControllerLan.Con_SelectedBarcodePrintedTemplatesAreInconsistent);
            }
            return Json(new { Message = message });
        }
        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_Inventory_Hu_New")]
        public JsonResult _PrintHuList(string checkedOrders)
        {
            string[] checkedOrderArray = checkedOrders.Split(',');
            string selectStatement = string.Empty;
            IList<object> selectPartyPara = new List<object>();
            foreach (var para in checkedOrderArray)
            {
                if (selectStatement == string.Empty)
                {
                    selectStatement = "from Hu where HuId in (?";
                }
                else
                {
                    selectStatement += ",?";
                }
                selectPartyPara.Add(para);
            }
            selectStatement += ")";

            IList<Hu> huList = genericMgr.FindAll<Hu>(selectStatement, selectPartyPara.ToArray());
            var defaultHuTemplate = this.systemMgr.GetEntityPreferenceValue(Entity.SYS.EntityPreference.CodeEnum.DefaultBarCodeTemplate);
            foreach (var hu in huList)
            {
                if (!string.IsNullOrEmpty(hu.ManufactureParty))
                {
                    hu.ManufacturePartyDescription = queryMgr.FindById<Party>(hu.ManufactureParty).Name;
                }

                if (string.IsNullOrWhiteSpace(hu.HuTemplate))
                {
                    hu.HuTemplate = defaultHuTemplate;
                }
                //if (!string.IsNullOrWhiteSpace(hu.Direction))
                //{
                //    hu.Direction = this.genericMgr.FindById<HuTo>(hu.Direction).CodeDescription;
                //}
            }
            var huGroupList = huList.GroupBy(p => p.HuTemplate, (k, g) => new { k, g });
            List<string> printUrls = new List<string>();
            foreach (var huGroup in huGroupList)
            {
                string reportFileUrl = PrintHuList(huGroup.g.ToList(), huGroup.k);
                printUrls.Add(reportFileUrl);
            }
            object obj = new { SuccessMessage = Resources.EXT.ControllerLan.Con_BarcodePrintedSuccessfully, PrintUrl = printUrls };
            return Json(obj);
        }

        public string PrintHuList(IList<Hu> huList, string huTemplate)
        {
            foreach (var hu in huList)
            {
                if (!string.IsNullOrWhiteSpace(hu.Direction))
                {
                    hu.Direction = this.genericMgr.FindById<HuTo>(hu.Direction).CodeDescription;
                }
            }
            IList<PrintHu> printHuList = Mapper.Map<IList<Hu>, IList<PrintHu>>(huList);

            IList<object> data = new List<object>();
            data.Add(printHuList);
            data.Add(CurrentUser.FullName);
            return reportGen.WriteToFile(huTemplate, data);
        }

        private IList<Hu> GetPartsHu(OrderMaster orderMaster, IList<OrderDetail> orderDetailList)
        {
            IList<Hu> huList = new List<Hu>();
            foreach (OrderDetail orderDetail in orderDetailList)
            {
                int huCount = Convert.ToInt32(orderDetail.HuQty % orderDetail.UnitCount == 0 ? orderDetail.HuQty / orderDetail.UnitCount : (orderDetail.HuQty / orderDetail.UnitCount) + 1);
                var lastHuQty = orderDetail.HuQty % orderDetail.UnitCount;
                for (int i = 0; i < huCount; i++)
                {
                    var item = this.itemMgr.GetCacheItem(orderDetail.Item);
                    Hu hu = new Hu();
                    //hu.HuId = huId;
                    hu.LotNo = orderDetail.LotNo;

                    hu.Qty = (i + 1 == huCount) ? (lastHuQty > 0 ? lastHuQty : orderDetail.UnitCount) : orderDetail.UnitCount;

                    hu.Item = orderDetail.Item;
                    hu.ItemDescription = orderDetail.ItemDescription;
                    hu.BaseUom = orderDetail.BaseUom;
                    hu.Uom = orderDetail.Uom;
                    hu.UnitCount = orderDetail.UnitCount;
                    hu.UnitQty = orderDetail.UnitQty;
                    hu.HuTemplate = orderMaster.HuTemplate;
                    hu.ManufactureParty = orderDetail.ManufactureParty;
                    hu.ManufactureDate = orderDetail.ManufactureDate;
                    hu.PrintCount = 0;
                    hu.ConcessionCount = 0;
                    hu.ReferenceItemCode = orderDetail.ReferenceItemCode;
                    //hu.IsOdd = hu.Qty < hu.UnitCount;
                    hu.IsChangeUnitCount = orderDetail.IsChangeUnitCount;
                    hu.UnitCountDescription = orderDetail.UnitCountDescription;
                    hu.SupplierLotNo = orderDetail.SupplierLotNo;
                    hu.ContainerDesc = orderDetail.ContainerDescription;
                    hu.LocationTo = string.IsNullOrWhiteSpace(orderDetail.LocationTo) ? orderMaster.LocationTo : orderDetail.LocationTo;
                    hu.OrderNo = orderDetail.OrderNo;
                    hu.Shift = orderMaster.Shift;
                    hu.Flow = orderMaster.Flow;

                    hu.MaterialsGroup = GetMaterialsGroupDescrption(item.MaterialsGroup);
                    //hu.HuOption = GetHuOption(item);
                    
                    huList.Add(hu);
                }
            }
            return huList;
        }

        private string GetMaterialsGroupDescrption(string materialsGroupCode)
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(materialsGroupCode))
                {
                    var itemCategorys = this.genericMgr.FindAll<string>
                        ("select Description from ItemCategory where Code = ? and SubCategory = ? ",
                        new object[] { materialsGroupCode, (int)CodeMaster.SubCategory.MaterialsGroup },
                        new NHibernate.Type.IType[] { NHibernateUtil.String, NHibernateUtil.Int32 });
                    if (itemCategorys != null && itemCategorys.Count > 0)
                    {
                        return itemCategorys[0];
                    }
                }
            }
            catch (Exception)
            { }
            return materialsGroupCode;
        }
        #endregion

        #endregion

        #region private method
        private SearchStatementModel PrepareSearchStatement(GridCommand command, HuSearchModel searchModel)
        {
            string whereStatement = string.Empty;

            IList<object> param = new List<object>();

            HqlStatementHelper.AddLikeStatement("HuId", searchModel.HuId, HqlStatementHelper.LikeMatchMode.Anywhere, "h", ref whereStatement, param);
            HqlStatementHelper.AddLikeStatement("CreateUserName", searchModel.CreateUserName, HqlStatementHelper.LikeMatchMode.Start, "h", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Item", searchModel.Item, "h", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("SupplierLotNo", searchModel.SupplierLotNo, "h", ref whereStatement, param);

            if (searchModel.LotNo != null & searchModel.LotNoTo != null)
            {
                HqlStatementHelper.AddBetweenStatement("LotNo", searchModel.LotNo, searchModel.LotNoTo, "h", ref whereStatement, param);
            }
            else if (searchModel.LotNo != null & searchModel.LotNoTo == null)
            {
                HqlStatementHelper.AddGeStatement("LotNo", searchModel.LotNo, "h", ref whereStatement, param);
            }
            else if (searchModel.LotNo == null & searchModel.LotNoTo != null)
            {
                HqlStatementHelper.AddLeStatement("LotNo", searchModel.LotNoTo, "h", ref whereStatement, param);
            }

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

            if (searchModel.RemindExpireDate_start != null & searchModel.RemindExpireDate_End != null)
            {
                HqlStatementHelper.AddBetweenStatement("RemindExpireDate", searchModel.RemindExpireDate_start, searchModel.RemindExpireDate_End, "h", ref whereStatement, param);
            }
            else if (searchModel.RemindExpireDate_start != null & searchModel.RemindExpireDate_End == null)
            {
                HqlStatementHelper.AddGeStatement("RemindExpireDate", searchModel.RemindExpireDate_start, "h", ref whereStatement, param);
            }
            else if (searchModel.RemindExpireDate_start == null & searchModel.RemindExpireDate_End != null)
            {
                HqlStatementHelper.AddLeStatement("RemindExpireDate", searchModel.RemindExpireDate_End, "h", ref whereStatement, param);
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

    }
}
