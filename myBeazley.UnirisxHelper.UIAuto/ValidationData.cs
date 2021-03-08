using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace myBeazley.UnirisxHelper.UIAuto
{
    public class ValidationData
    {
        public ValidationData()
        {
            Succes = new List<string>();
            Errors = new List<string>();
        }

        public List<string> Succes { get; set; }
        public List<string> Errors { get; set; }
        public string PolicyReference { get; set; }
        public string TestName { get; set; }
    }
}
