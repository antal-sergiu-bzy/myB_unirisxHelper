using myBeazley.UnirisxHelper.DataTransferObj.UISerialization;
using myBeazley.UnirisxHelper.UIAuto.DriverBase;
using OpenQA.Selenium;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace myBeazley.UnirisxHelper.UIAuto.UI
{
    public class Billing : POMHelpers
    {

        JsonHelper jsonHelper;
        private ValidationData _vd;

        public Billing(ValidationData vd)
        {
            jsonHelper = new JsonHelper();
            _vd = vd;
        }

        public RateChange GoToRateRateChange(ValidationData vd)
        {
            var rateChange = FindIWebElementByXPath("//td[text() = 'Rate Change']");
            rateChange.Click();

            return new RateChange(vd);
        }

        public ValidationData AssertPremiumValues(BeazleyUIDataModel data)
        {
            AssertNetPremium(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.NetPremium));
            AssertTaxAndFees(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.Tax));
            AssertCommission(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.Commission));
            AssertGrossPremium(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.GrossPremium));

            if (jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.TestName).Contains("_DD")) AssertNetAmountPayable(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.TotalPremium));
            else AssertNetAmountPayable(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.NetPremiumPayable));

            return _vd;
        }

        public void AssertCommission(ValidationData vd, string beazleyUIValue)
        {
            if (!beazleyUIValue.Equals("NOT FOUND"))
            {
                string unirisxValue = GetCommission();

                if (CheckValueIsInRange(beazleyUIValue, unirisxValue))
                {
                    vd.Succes.Add($"Billing Page: Commission: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
                }
                else vd.Errors.Add($"Billing Page: Commission: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
        }

        public void AssertGrossPremium(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetGrossPremium();

            if (CheckValueIsInRange(beazleyUIValue, unirisxValue))
            {
                vd.Succes.Add($"Billing Page: Gross Premium: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Billing Page: Gross Premium: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertTaxAndFees(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetTaxAndFees();

            if (CheckValueIsInRange(beazleyUIValue, unirisxValue))
            {
                vd.Succes.Add($"Billing Page: TaxAndFees : Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Billing Page: TaxAndFees : Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertNetPremium(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetNetPremium();

            if (CheckValueIsInRange(beazleyUIValue, unirisxValue))
            {
                vd.Succes.Add($"Billing Page: NetPremium : Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Billing Page: NetPremium : Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertNetAmountPayable(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetNetAmountPayable();

            if (CheckValueIsInRange(beazleyUIValue, unirisxValue))
            {
                vd.Succes.Add($"Billing Page: NetAmountPayable : Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Billing Page: NetAmountPayable : Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public string GetCommission()
        {
            var commision = FindIWebElementById("totalCommissionAmount_0");
            return GetValue(commision);
        }

        public string GetGrossPremium()
        {
            var grossPremium = FindIWebElementById("toatalGrossAmt_0");
            return GetValue(grossPremium);
        }

        public string GetTaxAndFees()
        {
            var taxAndFees = FindIWebElementById("totalTax_0");
            return GetValue(taxAndFees);
        }

        public string GetNetPremium()
        {
            var netPremium = FindIWebElementById("totalNetPrem_0");
            return GetValue(netPremium);
        }

        public string GetNetAmountPayable()
        {
            IWebElement netAmountPayable = null;
            try
            {
                netAmountPayable = FindIWebElementById("finalTotalSum_0");
            }
            catch (Exception ex) { }

            return GetValue(netAmountPayable);
        }
    }
}
