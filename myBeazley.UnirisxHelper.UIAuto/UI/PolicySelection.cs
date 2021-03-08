using myBeazley.UnirisxHelper.UIAuto.DriverBase;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace myBeazley.UnirisxHelper.UIAuto.UI
{
    public class PolicySelection : POMHelpers
    {

        ////td[contains(@class,'PolicyRefColumn')][1]
        ///

        public PolicySelection()
        {
                
        }

        public PolicySummary SelectPolicy(string rowNumberIndex)
        {
            var listOfPolicyReferences = FindIWebElementsByXPath("//td[contains(@class,'PolicyRefColumn')][1]//a");
            var policyToCheck = listOfPolicyReferences[int.Parse(rowNumberIndex)];

            policyToCheck.Click();

            return new PolicySummary();
        }
    }
}
