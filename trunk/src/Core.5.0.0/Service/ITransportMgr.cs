using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.TMS;

namespace com.Sconit.Service
{
    public interface ITransportMgr
    {
        string CreateTransportOrder(TransportOrderMaster transportOrderMaster, IList<string> ipNoList);

        void AddTransportOrderRoute(string orderNo, int seq, string shipAddress);

        void AddTransportOrderDetail(string orderNo, IList<string> ipNoList);


        void DeleteTransportOrderRoute(string orderNo, int transportOrderRouteId);


        void DeleteTransportOrderDetail(string orderNo, IList<string> ipNoList);

        void ReleaseTransportOrderMaster(TransportOrderMaster transportOrderMaster);

    }
}
