using com.Sconit.Entity;
using com.Sconit.Entity.Exception;
using com.Sconit.Utility;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using com.Sconit.Entity.TMS;

namespace com.Sconit.Utility
{
    public static class TMSHelper
    {
       
       

    

        public static IList<string> GetPlaceList(string shipFrom, string shipTo, string morePlace)
        {
            List<string> placeList = new List<string>();
            placeList.Add(shipFrom);
            if (!string.IsNullOrEmpty(morePlace))
            {
                string[] places = ISIHelper.GetUserSplit(morePlace)[0].Split(new char[] { ',' });
                placeList.AddRange(places.ToList());
            }
            placeList.Add(shipTo);
            placeList.Add(shipFrom);
            return placeList;
        }

        public static string GetDetail(string no, IList<WaybillItem> waybillItemList, ref bool isHasVolume)
        {
            StringBuilder detail = new StringBuilder();
            if (waybillItemList != null && waybillItemList.Count > 0)
            {
                decimal qty = waybillItemList.Sum(i => i.Qty);
                decimal recQty = waybillItemList.Sum(i => i.RecQty);
                decimal volume = waybillItemList.Sum(i => i.Volume);
                detail.Append("cssbody=[obbd] cssheader=[obhd] header=[" + no + " ${TMS.Waybill.ShipQty}" + qty.ToString("0.##") + " ${TMS.Waybill.RecQty}" + recQty.ToString("0.##") + " ${TMS.Waybill.ActVolume}");
                if (volume == 0)
                {
                    detail.Append("<span style='color: Red;'>");
                }
                detail.Append(volume.ToString("0.##"));
                if (volume == 0)
                {
                    detail.Append("</span>");
                }
                detail.Append("] body=[<table width=100%>");
                foreach (WaybillItem waybillItem in waybillItemList)
                {
                    string itemCode = waybillItem.Item;
                    string itemDesc = waybillItem.Desc1.Replace("[", "&#91;").Replace("]", "&#93;");
                    string shipQty = waybillItem.Qty.ToString("0.##");
                    string uom = waybillItem.UOM;
                    string RecQty = waybillItem.RecQty.ToString("0.##");
                    detail.Append("<tr><td>" + itemCode + "</td><td>" + itemDesc + "</td><td>" + shipQty + "</td><td>" + uom + "</td><td>" + RecQty + "</td><td>");
                    if (waybillItem.Volume == 0)
                    {
                        detail.Append("<span style='color: Red;'>");
                        isHasVolume = false;
                    }
                    detail.Append(waybillItem.Volume.ToString("0.##"));
                    if (waybillItem.Volume == 0)
                    {
                        detail.Append("</span>");
                    }
                    detail.Append("</td></tr>");
                }
                detail.Append("</table>]");
            }
            return detail.ToString();
        }

        public static string[] FlowDet2WaybillCloneFields = new string[] 
            {                 
                "PricingMethod",
                "PriceList",
                "BillAddr",
                "Currency",
                "RoundUpOpt"               
            };


        public static string[] PriceListDet2WaybillCloneFields = new string[] 
            {                 
                "UnitPrice",
                "MinPrice",
                "MaxPrice",
                "SendFee",
                "InOutFee",
                "ServiceFee",
                "IsProvEst"             
            };

    }
}
