using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using MoreLinq;
using myBeazley.UnirisxHelper.DataTransferObj.UISerialization;
using myBeazley.UnirisxHelper.UIAuto;
using myBeazley.UnirisxHelper.UIAuto.BaseDriver;
using myBeazley.UnirisxHelper.UIAuto.UI;
using Newtonsoft.Json;
using NUnit.Framework;

namespace myBeazley.UnirisxHelper.Testing
{
    public class TestingUnirisx : BaseUnirisxDriver
    {
        private static string _phaseNo = "3";
        public List<BeazleyUIDataModel> listOfRetrievedData = null;
        private List<ValidationData> resultObjects = new List<ValidationData>();

        public TestingUnirisx(string phaseNo) { _phaseNo = phaseNo; }
        public TestingUnirisx() { }

        public static List<BeazleyUIDataModel> GetJsonData()
        {
            JsonHelper jsonHelper = new JsonHelper();
            List<BeazleyUIDataModel> dataTemplateList = jsonHelper.DeserializeJson($"{JsonHelper.GetJsonFile()}", _phaseNo);

            return dataTemplateList;
        }

        private void AfterAll()
        {
            JsonHelper jsonHelper = new JsonHelper();
            using (var streamWriter = new StreamWriter(JsonHelper.CreateAndRetrieveResultsFilePath(_phaseNo)))
            {
                foreach (var validationData in resultObjects)
                {
                    streamWriter.WriteLine(validationData.PolicyReference + " / " + validationData.TestName + " / " + $"Phase: {_phaseNo}");

                    foreach (var succes in validationData.Succes)
                    {
                        streamWriter.WriteLine(succes);
                    }
                    streamWriter.WriteLine("*************");

                    foreach (var error in validationData.Errors)
                    {
                        streamWriter.WriteLine(error);
                    }
                    streamWriter.WriteLine();
                }
            }
        }

        [Test]
        public void ExecuteOneByOne()
        {
            listOfRetrievedData = GetJsonData();
            foreach (var data in listOfRetrievedData)
            {
                var vd = MainTestMethod(data);
                resultObjects.Add(vd);
                AfterTests();
            }
            AfterAll();
        }

        [Test]
        private ValidationData MainTestMethod(BeazleyUIDataModel data)
        {
            SetUpChromeInstance();
            ValidationData validationData = new ValidationData();
            JsonHelper jsonHelper = new JsonHelper();
            Billing billing = null;
            try
            {
                var loginPage = new LoginPage();
                var homePage = loginPage.Login(data.Product);
                var policySelection = homePage.SearchPolicy(jsonHelper.GetPolicyReference(data), jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.InsuredName));
                var policySummary = policySelection.SelectPolicy(jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.RowNumberToCheck));

                if (jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.IsBrexit).Equals("True"))
                {
                    validationData = policySummary.AssertDates(data, validationData);
                    var interestPage = policySummary.GoToInterestPage(validationData);
                    validationData = interestPage.AssertInterestPageValues(data);
                }
                else
                {
                    validationData = policySummary.AssertPremiumValues(data, validationData);
                    billing = policySummary.GoToBillingPage(validationData);
                    validationData = billing.AssertPremiumValues(data);
                }

                if (data.Product.Contains("Marine") && jsonHelper
                    .GetValueDataFromBeazleyDictionary(data, HelperConstants.TestType).Equals("Renewal"))
                {
                    var rateChange = billing.GoToRateRateChange(validationData);
                    validationData = rateChange.AssertRateChangeValues(data);
                }


            }
            catch (Exception ex)
            {
                validationData.PolicyReference += $" / Test: {jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.TestName)} failed.";
            }

            return validationData;
        }


        #region Parallel run

        //[Test]
        //[Ignore("CURRENTLY NOT WORKING, INVESTIGATION NEEDED")]
        //private void ExecuteInParallel()
        //{
        //    listOfRetrievedData = GetJsonData();
        //    RunAllTestsRecursively();
        //    AfterAll();
        //}

        //private void RunAllTestsRecursively()
        //{
        //    while (!listOfRetrievedData.Count.Equals(0))
        //    {
        //        List<BeazleyUIDataModel> copiedObjects = new List<BeazleyUIDataModel>();
        //        foreach (var data in listOfRetrievedData) { copiedObjects.Add(data); }

        //        var listOfTasks = new List<Task<ValidationData>>();

        //        if (copiedObjects.Count > 4)
        //        {
        //            for (int i = 0; i < 4; i++)
        //            {
        //                var task = Task<ValidationData>.Factory.StartNew(() => MainTestMethod(copiedObjects[i]));
        //                listOfTasks.Add(task);
        //                listOfRetrievedData.RemoveAt(0);
        //            }
        //        }
        //        else
        //        {
        //            foreach (var remainingData in copiedObjects)
        //            {
        //                var task = Task<ValidationData>.Factory.StartNew(() => MainTestMethod(remainingData));
        //                listOfTasks.Add(task);
        //                listOfRetrievedData.RemoveAt(0);
        //            }
        //        }

        //        Task.WaitAll(listOfTasks.ToArray());

        //        foreach (var task in listOfTasks)
        //        {
        //            resultObjects.Add(task.Result);
        //        }
        //        AfterTests();
        //    }
        //}

        #endregion
    }
}
