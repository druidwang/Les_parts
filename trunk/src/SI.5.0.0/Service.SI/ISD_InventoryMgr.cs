namespace com.Sconit.Service.SI
{
    using System;
    using System.Collections.Generic;
    using com.Sconit.Entity.SI.SD_INV;

    public interface ISD_InventoryMgr
    {
        Hu GetHu(string huId);

        Hu CloneHu(string huId, decimal qty);
        
        Entity.SI.SD_INV.StockTakeMaster GetStockTake(string stNo);

        void DoStockTake(string stNo, string[][] stockTakeDetails);

        void DoPutAway(string huId, string binCode);

        void DoPickUp(string huId);

        void DoPack(List<string> huIdList, string location, DateTime? effDate);

        void DoUnPack(List<string> huIdList, DateTime? effDate);

        void DoRePack(List<string> oldHuList, List<string> newHuList, DateTime? effDate);

        void InventoryUnFreeze(IList<string> huIdList);

        void InventoryFreeze(IList<string> huIdList);

        Hu GetDistHu(string huId);

        Hu ResolveHu(string extHuId);
    }
}
