﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;

namespace com.Sconit.Web.Models.SearchModels.MRP
{
    public class MrpExWorkHourSearchModel : SearchModelBase
    {
        public string Flow { get; set; }
        public DateTime DateFrom { get; set; }
        public DateTime DateTo { get; set; }
    }
}