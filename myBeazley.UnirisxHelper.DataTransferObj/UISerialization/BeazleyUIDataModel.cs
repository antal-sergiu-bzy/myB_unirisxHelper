using System;
using System.Collections.Generic;
using System.Text;

namespace myBeazley.UnirisxHelper.DataTransferObj.UISerialization
{
    public class BeazleyUIDataModel
    {
        public string Product { get; set; }
        public Dictionary<string, PolicyDetail> PolicyDetails { get; set; }
    }
}
