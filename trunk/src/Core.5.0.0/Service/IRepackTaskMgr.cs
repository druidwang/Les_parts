using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.WMS;

namespace com.Sconit.Service
{
    public interface IRepackTaskMgr
    {
        void AssignRepackTask(IList<RepackTask> repackTaskList,string assignUser);
    }
}
