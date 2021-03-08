using myBeazley.UnirisxHelper.DataTransferObj.UISerialization;
using myBeazley.UnirisxHelper.UIAuto.DriverBase;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace myBeazley.UnirisxHelper.UIAuto.UI
{
    public class Interest : POMHelpers
    {
        JsonHelper jsonHelper;
        private ValidationData _vd;

        public Interest(ValidationData vd)
        {
            jsonHelper = new JsonHelper();
            _vd = vd;
        }

        public ValidationData AssertInterestPageValues(BeazleyUIDataModel data)
        {
            AssertUnderwritingPlatform(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.UNDERWRITING_PLATFORM));
            AssertServiceCompanyCode(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.SERIVCE_COMPANY_CODE));
            AssertCobCode(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.COB_CODE));
            AssertTriFocus(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.TRI_FOCUS));
            AssertStatCode(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.STAT_CODE));
            AssertRiskCode(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.RISK_CODE));
            AssertBinderReference(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.BINDER_REFERENCE));
            AssertUMR(_vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.UMR));

            return _vd;
        }


        public void AssertCobCode(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetCobCode();

            if (unirisxValue.Equals(beazleyUIValue, StringComparison.InvariantCultureIgnoreCase))
            {
                vd.Succes.Add($"Interest Page: COB_CODE: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Interest Page: COB_CODE: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertTriFocus(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetTriFocus();

            if (unirisxValue.Equals(beazleyUIValue))
            {
                vd.Succes.Add($"Interest Page: TRI_FOCUS: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Interest Page: TRI_FOCUS: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertStatCode(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetStatCode();

            if (unirisxValue.Equals(beazleyUIValue))
            {
                vd.Succes.Add($"Interest Page: STAT_CODE: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Interest Page: STAT_CODE: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertRiskCode(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetRiskCode();

            if (unirisxValue.Equals(beazleyUIValue))
            {
                vd.Succes.Add($"Interest Page: RISK_CODE: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Interest Page: RISK_CODE: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertServiceCompanyCode(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetServiceCompanyCode();

            if (unirisxValue.Equals(beazleyUIValue))
            {
                vd.Succes.Add($"Interest Page: SERVICE_COMPANY_CODE: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Interest Page: SERVICE_COMPANY_CODE: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertUnderwritingPlatform(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetUnderwritingPlatform();

            if (unirisxValue.Equals(beazleyUIValue))
            {
                vd.Succes.Add($"Interest Page: UNDERWRITING_PLATFORM: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Interest Page: UNDERWRITING_PLATFORM: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertBinderReference(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetBinderReference();

            if (unirisxValue.Equals(beazleyUIValue))
            {
                vd.Succes.Add($"Interest Page: BINDER_REFERENCE: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Interest Page: BINDER_REFERENCE: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertUMR(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetUMR();

            if (unirisxValue.Equals(beazleyUIValue))
            {
                vd.Succes.Add($"Interest Page: UMR: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"Interest Page: UMR: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }



        public string GetCobCode()
        {
            var uiElement = FindIWebElementById("CobCodeEnv_7880_0_0");
            return SplitAndReturnLastValue(GetInnerText(uiElement));
        }

        public string GetTriFocus()
        {
            var uiElement = FindIWebElementById("TrifocusEO_7880_0_0");
            return SplitAndReturnLastValue(GetInnerText(uiElement));
        }

        public string GetStatCode()
        {
            var uiElement = FindIWebElementById("StatCode_7880_0_0");
            return SplitAndReturnLastValue(GetInnerText(uiElement));
        }

        public string GetRiskCode()
        {
            var uiElement = FindIWebElementById("RiskCodeEO_7880_0_0");
            return SplitAndReturnLastValue(GetInnerText(uiElement));
        }

        public string GetServiceCompanyCode()
        {
            var uiElement = FindIWebElementById("ServiceCompany_7880_0_0");
            return SplitAndReturnLastValue(GetInnerText(uiElement));
        }

        
        public string GetUnderwritingPlatform()
        {
            var uiElement = FindIWebElementById("UnderwritingPlatform_7880_0_0");
            return SplitAndReturnLastValue(GetInnerText(uiElement));
        }

        public string GetBinderReference()
        {
            var uiElement = FindIWebElementById("BinderRefEO_7880_0_0");
            return SplitAndReturnLastValue(GetInnerText(uiElement));
        }

        public string GetUMR()
        {
            var uiElement = FindIWebElementById("UMREO_7880_0_0");
            return SplitAndReturnLastValue(GetInnerText(uiElement));
        }
    }
}
