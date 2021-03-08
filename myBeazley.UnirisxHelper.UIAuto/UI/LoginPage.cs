using Beazley.AutomationFramework.UIClient.Selenium.BasePage;
using myBeazley.UnirisxHelper.UIAuto.BaseDriver;
using myBeazley.UnirisxHelper.UIAuto.DriverBase;
using System;
using System.Collections.Generic;
using System.Text;

namespace myBeazley.UnirisxHelper.UIAuto.UI
{
    public class LoginPage : POMHelpers
    {

        public LoginPage(string url = "https://uat-bz.owitglobal.com")  : base(url) {}
        
        
        public HomePage Login(string product)
        {
            var userName = FindIWebElementById("frmLoginForm:username");
            var password = FindIWebElementById("frmLoginForm:password");
            var loginButton = FindIWebElementById("frmLoginForm:Login");

            if (product.Contains("PCG"))
            {
                userName.SendKeys("PCGsimonasUAT");
                password.SendKeys("PassUAT123");
            }
            else
            {
                userName.SendKeys("BAsimonasUAT");
                password.SendKeys("ChangeMe123");
            }

            loginButton.Click();

            return new HomePage();
        }
    }
}
