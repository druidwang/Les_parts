using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace com.Sconit.Entity.SI.MES
{
    public class MaterialIORequest
    {
        public string RequestId { get; set; }

        public List<MES_Interface_MaterialIO> Data { get; set; }

        public string Requester { get; set; }

        public DateTime RequestDate { get; set; }
    }
}
