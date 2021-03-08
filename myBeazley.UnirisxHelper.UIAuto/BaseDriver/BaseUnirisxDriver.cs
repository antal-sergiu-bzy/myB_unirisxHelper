using Beazley.AutomationFramework.UIClient.Selenium.BasePage;
using Beazley.AutomationFramework.UIClient.Selenium.Helpers;
using NUnit.Framework;
using OpenQA.Selenium.Chrome;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;

namespace myBeazley.UnirisxHelper.UIAuto.BaseDriver
{
    public class BaseUnirisxDriver
    {
        public DriverFactory DriverFactory;
        public BeazleyDriver BeazleyDriver;
        public string BrowserOptionsJsonPath = AppDomain.CurrentDomain.BaseDirectory + "browserOptions.json";
        private string BinDebugRoot = AppDomain.CurrentDomain.BaseDirectory;
        private int DefaultImplicitWait = 120;


        public void SetUpChromeInstance()
        {
            DriverFactory = new DriverFactory();
            DownloadJSON();
            DriverFactory.LoadDriverOptions("/browserOptions.json");
            DriverFactory.CreateDrivers(Browsers.Chrome);
            BeazleyDriver = DriverFactory.GetBeazleyDriver();
            BeazleyDriver.SetImplicitWait(DefaultImplicitWait);
        }

        public void AfterTests()
        {
            System.GC.Collect();
            System.GC.WaitForPendingFinalizers();

            try
            {
                foreach (var process in Process.GetProcessesByName("chromedriver"))
                {
                    process.Kill();
                    process.WaitForExit();
                }
            }
            catch (Exception ex) { }

            try
            {
                foreach (var process in Process.GetProcessesByName("chrome"))
                {
                    process.Kill();
                    process.WaitForExit();
                }
            }
            catch (Exception ex) { }
        }

        /// <summary>
        ///  Create a webclient to download the browserOptions.json to bin/Debug
        /// </summary>
        private void DownloadJSON()
        {
            DirectoryInfo dInfo = new DirectoryInfo(BinDebugRoot);
            var arrayOfFiles = dInfo.GetFiles().Where(file => file.Name.Contains("browserOptions")).ToList();

            if (arrayOfFiles.Count < 1)
            {
                using (WebClient client = new WebClient())
                {
                    client.DownloadFile("http://git.bfl.local/raw/Beazley/myBeazley_Octopus/master/Beazley.ScallingJobs/browserOptions.json", BrowserOptionsJsonPath);
                }
            }
        }

    }
}
