using Beazley.AutomationFramework.UIClient.Selenium.BasePage;
using myBeazley.UnirisxHelper.UIAuto.DriverBase;
using OpenQA.Selenium.Chrome;
using System;
using System.Collections.Generic;
using System.Text;

namespace myBeazley.UnirisxHelper.UIAuto.UI
{
    public class HomePage : POMHelpers
    {

        public PolicySelection SearchPolicy(string policyRef, string insuredName)
        {
            var insuredNameField = FindIWebElementById("homePage:tfClientName");
            insuredNameField.SendKeys(insuredName);

            var policyRefField = FindIWebElementById("homePage:tfPolicyReference");
            policyRefField.SendKeys(policyRef);

            var searchButton = FindIWebElementByXPath("//a/span[text() = 'Search' or contains(text(), 'Search')]");
            searchButton.Click();

            return new PolicySelection();
        }


    }
}
