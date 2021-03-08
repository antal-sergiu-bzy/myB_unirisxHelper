using Beazley.AutomationFramework.UIClient.Selenium.BasePage;
using OpenQA.Selenium;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace myBeazley.UnirisxHelper.UIAuto.DriverBase
{
    public class POMHelpers : BasePage
    {
        public POMHelpers(string url = "") : base(url) { }

        public void ClickElement(IWebElement element)
        {
            BeazleyDriver.WaitForBeClickable(element);
            element.Click();

        }

        public IWebElement FindIWebElementByXPath(string value)
        {
            return BeazleyDriver.WebDriver.FindElement(By.XPath(value));
        }

        public ReadOnlyCollection<IWebElement> FindIWebElementsByXPath(string value)
        {
            return BeazleyDriver.WebDriver.FindElementsByXPath(value);
        }

        public IWebElement FindIWebElementById(string value)
        {
            return BeazleyDriver.WebDriver.FindElement(By.Id(value));
        }

        public string GetInnerText(IWebElement element)
        {
            Thread.Sleep(300);
            BeazleyDriver.WaitForVisibility(element, 5);
            BeazleyDriver.WaitForPendingAjaxTasks();

            return element.Text;
        }

        public string GetValue(IWebElement element)
        {
            Thread.Sleep(300);
            BeazleyDriver.WaitForVisibility(element);
            BeazleyDriver.WaitForPendingAjaxTasks();
            return element.GetAttribute("value");
        }

        public string SplitAndReturnLastValue(string input)
        {
            var elements = input.Replace("\r\n","~").Split('~');
            return elements.Last();
        }

        public bool CheckValueIsInRange(string beazleyUIVal,string unirisxUIVal, double range = 0.02)
        {
            double beazleyUIValDouble = Convert.ToDouble(beazleyUIVal);
            double unirisxUIValDouble = Convert.ToDouble(unirisxUIVal);

            if ((unirisxUIValDouble - range) <= beazleyUIValDouble && (unirisxUIValDouble + range) >= beazleyUIValDouble) return true;
            else return false;
        }
    }
}
