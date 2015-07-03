using System.Collections.Generic;
using com.Sconit.Entity.SCM;
using System.IO;

namespace com.Sconit.Service
{
    public interface IFlowMgr
    {
        IList<FlowBinding> GetFlowBinding(string flow);
        FlowStrategy GetFlowStrategy(string flow);
        IList<FlowDetail> GetFlowDetailList(FlowMaster flowMaster);
        IList<FlowDetail> GetFlowDetailList(FlowMaster flowMaster, bool includeInactiveDetail);
        IList<FlowDetail> GetFlowDetailList(FlowMaster flowMaster, bool includeInactiveDetail, bool includeReferenceFlow);

        IList<FlowDetail> GetFlowDetailList(string flowCode);
        IList<FlowDetail> GetFlowDetailList(string flowCode, bool includeInactiveDetail);
        IList<FlowDetail> GetFlowDetailList(string flowCode, bool includeInactiveDetail, bool includeReferenceFlow);

        FlowMaster GetReverseFlow(FlowMaster flow, IList<string> itemCodeList);
        void CreateFlow(FlowMaster flowMaster);
        void UpdateFlowStrategy(FlowStrategy flowstrategy);
        void DeleteFlow(string flow);
        void CreateFlowDetail(FlowDetail flowDetail);
        void UpdateFlowDetail(FlowDetail flowDetail);
        FlowMaster GetAuthenticFlow(string flowCode);

        void ImportFlow(Stream inputStream, CodeMaster.OrderType flowType);
    }
}
