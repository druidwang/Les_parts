﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.PrintModel.INV;

namespace com.Sconit.Utility.Report.Operator
{
    public class RepBarCodeFIOperator : RepTemplate2
    {
        public RepBarCodeFIOperator()
        {

            //明细部分的行数
            this.pageDetailRowCount = 9;
            //列数   1起始
            this.columnCount = 4;

            this.rowCount = 9;
            //报表头的行数  1起始
            this.leftColumnHeadCount = 0;
            //报表尾的行数  1起始
            this.bottomRowCount = 0;

            this.headRowCount = 0;

        }

        /**
         * 需要拷贝的数据与合并单元格操作
         * 
         * Param pageIndex 页号
         */
        public override void CopyPageValues(int pageIndex)
        {
            this.SetMergedRegionColumn(pageIndex, 0, 1, 0, 2);
            this.SetMergedRegionColumn(pageIndex, 1, 1, 1, 3);

            this.SetMergedRegionColumn(pageIndex, 2, 1, 2, 3);
            this.SetMergedRegionColumn(pageIndex, 6, 0, 6, 3);
            this.SetMergedRegionColumn(pageIndex, 7, 0, 7, 3);

            this.SetColumnCell(pageIndex, 0, 0, "物料号：");
            this.SetColumnCell(pageIndex, 1, 0, "名  称：");
            this.SetColumnCell(pageIndex, 2, 0, "参考号：");
            this.SetColumnCell(pageIndex, 3, 0, "数  量：");
            this.SetColumnCell(pageIndex, 4, 0, "生产单：");
            this.SetColumnCell(pageIndex, 5, 0, "班  次：");
            this.SetColumnCell(pageIndex, 8, 0, "打印人：");
            this.SetColumnCell(pageIndex, 3, 2, "车  型：");
            this.SetColumnCell(pageIndex, 4, 2, "制造日期：");
            this.SetColumnCell(pageIndex, 5, 2, "包装物：");
            this.SetColumnCell(pageIndex, 8, 2, "打印时间：");
            //this.CopyCellColumn(pageIndex, 0, 0, "A1");
            //this.CopyCellColumn(pageIndex, 1, 0, "A2");
            //this.CopyCellColumn(pageIndex, 2, 0, "A3");
            //this.CopyCellColumn(pageIndex, 3, 0, "A4");
            //this.CopyCellColumn(pageIndex, 4, 0, "A5");
            //this.CopyCellColumn(pageIndex, 5, 0, "A6");
            //this.CopyCellColumn(pageIndex, 8, 0, "A9");
            //this.CopyCellColumn(pageIndex, 3, 2, "C4");
            //this.CopyCellColumn(pageIndex, 4, 2, "C5");
            //this.CopyCellColumn(pageIndex, 5, 2, "C6");
            //this.CopyCellColumn(pageIndex, 8, 2, "C9");
        }

        /**
         * 填充报表
         * 
         * Param list [0]huDetailList
         */
        protected override bool FillValuesImpl(String templateFileName, IList<object> list)
        {
            try
            {
                IList<PrintHu> huList = null;
                if (list[0].GetType() == typeof(PrintHu))
                {
                    huList = new List<PrintHu>();
                    huList.Add((PrintHu)list[0]);
                }
                else if (list[0].GetType() == typeof(List<PrintHu>))
                {
                    huList = (IList<PrintHu>)list[0];
                }
                else
                {
                    return false;
                }

                string userName = "";
                if (list.Count == 2)
                {
                    userName = (string)list[1];
                }

                this.sheet.DisplayGridlines = false;
                this.sheet.IsPrintGridlines = false;

                //this.sheet.DisplayGuts = false;

                int count = 0;
                foreach (PrintHu hu in huList)
                {
                    count++;
                }

                if (count == 0) return false;

                this.barCodeFontName = this.GetBarcodeFontName(6, 0);

                //加页删页
                //纵向打印
                this.CopyPageCloumn(count, columnCount, 1);

                int pageIndex = 1;

                foreach (PrintHu hu in huList)
                {
                    // 物料号
                    this.SetColumnCell(pageIndex, 0, 1, hu.Item);

                    //打印次数
                    //this.SetColumnCell(pageIndex, 1, 3, hu.PrintCount.ToString("0.########"));

                    // 物料名称
                    this.SetColumnCell(pageIndex, 1, 1, hu.ItemDescription);
                    //参考号
                    this.SetColumnCell(pageIndex, 2, 1, hu.ReferenceItemCode);
                    //数  量
                    this.SetColumnCell(pageIndex, 3, 1, string.Format("{0} {1}", hu.Qty.ToString("0.###"), hu.Uom));
                    //车  型
                    this.SetColumnCell(pageIndex, 3, 3, hu.MaterialsGroup);
                    //生产单号
                    this.SetColumnCell(pageIndex, 4, 1, hu.OrderNo);
                    //制造日期 
                    this.SetColumnCell(pageIndex, 4, 3, string.Format("{0}", hu.ManufactureDate.ToString("yyyyMMdd")));
                    //班  次
                    this.SetColumnCell(pageIndex, 5, 1, GetShiftName(hu.Shift));
                    //包装物
                    this.SetColumnCell(pageIndex, 5, 3, hu.ManufactureParty);
                    // 条形码
                    string barCode = Utility.BarcodeHelper.GetBarcodeStr(hu.HuId, this.barCodeFontName);
                    this.SetColumnCell(pageIndex, 6, 0, barCode);
                    //条码
                    this.SetColumnCell(pageIndex, 7, 0, hu.HuId);
                    //打印人
                    this.SetColumnCell(pageIndex, 8, 1, userName);
                    // 打印时间
                    this.SetColumnCell(pageIndex, 8, 3, DateTime.Now.ToString("yyyy/MM/dd HH:mm"));

                    // 零件号
                    //this.SetColumnCell(pageIndex, 3, 1, hu.Item);



                    //// 客户零件号
                    //this.SetColumnCell(pageIndex, 4, 1, hu.ReferenceItemCode);
                    //// 数量
                    //this.SetColumnCell(pageIndex, 5, 1, hu.Qty.ToString("0.########"));
                    ////单位
                    //this.SetColumnCell(pageIndex, 5, 3, hu.Uom);
                    ////包装
                    //this.SetColumnCell(pageIndex, 6, 3, hu.UnitCount.ToString("0.########"));
                    //// 生产线
                    //this.SetColumnCell(pageIndex, 7, 1, hu.Flow);


                    pageIndex++;

                }

            }
            catch (Exception e)
            {
                return false;
            }

            return true;
        }
    }
}
