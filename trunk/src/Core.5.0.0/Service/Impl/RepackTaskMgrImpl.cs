using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using com.Sconit.Entity.WMS;
using com.Sconit.Entity.INV;
using com.Sconit.Entity.Exception;
using com.Sconit.Entity;
using com.Sconit.Entity.ACC;
using System.Data;
using System.Data.SqlClient;

namespace com.Sconit.Service.Impl
{
    public class RepackTaskMgrImpl : BaseMgr, IRepackTaskMgr
    {
        public IGenericMgr genericMgr { get; set; }

        public void AssignRepackTask(IList<RepackTask> repackTaskList, string assignUser)
        {
            if (repackTaskList != null && repackTaskList.Count > 0)
            {
                User lastModifyUser = SecurityContextHolder.Get();
                User user = genericMgr.FindById<User>(Convert.ToInt32(assignUser));
                foreach (RepackTask p in repackTaskList)
                {
                    p.RepackUserId = user.Id;
                    p.RepackUserName = user.FullName;
                    p.LastModifyDate = DateTime.Now;
                    p.LastModifyUserId = lastModifyUser.Id;
                    p.LastModifyUserName = lastModifyUser.FullName;
                    genericMgr.Update(p);
                }

            }
        }


        public IList<string> SuggestRepackIn(int repackTaskId)
        {
            List<string> huList = new List<string>();
            return huList;
        }

        public void ProcessRepackResult(int repackTaskId, IList<string> repackResultIn, IList<string> repackResultOut, DateTime? effectiveDate)
        {
        }
    }
}
