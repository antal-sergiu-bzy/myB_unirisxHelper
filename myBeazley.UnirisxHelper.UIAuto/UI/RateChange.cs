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
    public class RateChange : POMHelpers
    {

        JsonHelper jsonHelper;
        private ValidationData _vd;

        public RateChange(ValidationData vd)
        {
            jsonHelper = new JsonHelper();
            _vd = vd;
        }

        public ValidationData AssertRateChangeValues(BeazleyUIDataModel data)
        {
            AssertRateChangeValue(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.RateChange));
            AssertPremiumChangeDueToExcess(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.ExcessChange));
            AssertPremiumChangeDueToSI(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.SumInsuredChange));
            AssertOtherChanges(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.OtherChanges));
            AssertRiskAdjustedRateChange(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.RiskAdjChange));

            return _vd;
        }

        public void AssertRateChangeValue(ValidationData vd, string beazleyUIValue)
        {
            if (!beazleyUIValue.Equals("NOT FOUND"))
            {
                string unirisxValue = GetRateChange();

                if (unirisxValue.Contains(beazleyUIValue))
                {
                    vd.Succes.Add($"Rate Change Page: RateChange: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
                }
                else vd.Errors.Add($"Rate Change Page: RateChange: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
        }

        public string GetRateChange()
        {
            var value = FindIWebElementById("nbController:rateChange");
            return GetValue(value);
        }

        public void AssertPremiumChangeDueToExcess(ValidationData vd, string beazleyUIValue)
        {
            if (!beazleyUIValue.Equals("NOT FOUND"))
            {
                string unirisxValue = GetPremiumChangeDueToExcess();

                if (unirisxValue.Contains(beazleyUIValue))
                {
                    vd.Succes.Add($"Rate Change Page: PremiumChangeDueToExcess: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
                }
                else vd.Errors.Add($"Rate Change Page: PremiumChangeDueToExcess: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
        }

        public string GetPremiumChangeDueToExcess()
        {
            var value = FindIWebElementById("QuestionId_3399");
            return GetValue(value);
        }

        public void AssertPremiumChangeDueToSI(ValidationData vd, string beazleyUIValue)
        {
            if (!beazleyUIValue.Equals("NOT FOUND"))
            {
                string unirisxValue = GetPremiumChangeDueToSI();

                if (unirisxValue.Contains(beazleyUIValue))
                {
                    vd.Succes.Add($"Rate Change Page: PremiumChangeDueToSI: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
                }
                else vd.Errors.Add($"Rate Change Page: PremiumChangeDueToSI: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
        }

        public string GetPremiumChangeDueToSI()
        {
            var value = FindIWebElementById("QuestionId_3400");
            return GetValue(value);
        }

        public void AssertOtherChanges(ValidationData vd, string beazleyUIValue)
        {
            if (!beazleyUIValue.Equals("NOT FOUND"))
            {
                string unirisxValue = GetOtherChanges();

                if (unirisxValue.Contains(beazleyUIValue))
                {
                    vd.Succes.Add($"Rate Change Page: OtherChanges: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
                }
                else vd.Errors.Add($"Rate Change Page: OtherChanges: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
        }

        public string GetOtherChanges()
        {
            var value = FindIWebElementById("QuestionId_3401");
            return GetValue(value);
        }

        public void AssertRiskAdjustedRateChange(ValidationData vd, string beazleyUIValue)
        {
            if (!beazleyUIValue.Equals("NOT FOUND"))
            {
                string unirisxValue = GetRiskAdjustedRateChange();

                if (unirisxValue.Contains(beazleyUIValue))
                {
                    vd.Succes.Add($"Rate Change Page: RiskAdjustedRateChange: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
                }
                else vd.Errors.Add($"Rate Change Page: RiskAdjustedRateChange: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
        }

        public string GetRiskAdjustedRateChange()
        {
            var value = FindIWebElementById("QuestionId_3398");
            return GetValue(value);
        }
    }
}
