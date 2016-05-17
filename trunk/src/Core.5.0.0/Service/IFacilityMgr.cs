using System;
using com.Sconit.Entity.BIL;
using com.Sconit.Entity.ORD;
using System.Collections.Generic;
using com.Sconit.Entity.VIEW;
using com.Sconit.Entity.FMS;

namespace com.Sconit.Service
{
    public interface IFacilityMgr
    {
        void CreateFacilityMaster(FacilityMaster facilityMaster);

        void GetFacilityControlPoint(string facilityName);
    }
}
