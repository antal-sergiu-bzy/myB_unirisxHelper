using myBeazley.UnirisxHelper.DataTransferObj.UISerialization;
using myBeazley.UnirisxHelper.UIAuto.DriverBase;
using NUnit.Framework;

namespace myBeazley.UnirisxHelper.UIAuto.UI
{
    public class PolicySummary : POMHelpers
    {
        //StringAssert.Contains(assertStrings.businessName, ogSummary.GetBusinessName());
        //StringAssert.Contains(assertStrings.adressLine1, ogSummary.GetAdress());
        //StringAssert.Contains(assertStrings.adressLine2, ogSummary.GetAdress());
        //StringAssert.Contains(assertStrings.postcode, ogSummary.GetAdress());

        JsonHelper jsonHelper;

        public PolicySummary()
        {
            jsonHelper = new JsonHelper();
        }

        public Billing GoToBillingPage(ValidationData vd)
        {
            var billingTab = FindIWebElementByXPath("//td[text() = 'Billing']");
            billingTab.Click();

            return new Billing(vd);
        }

        public Interest GoToInterestPage(ValidationData vd)
        {
            var billingTab = FindIWebElementByXPath("//td[text() = 'Interest']");
            billingTab.Click();

            return new Interest(vd);
        }

        public ValidationData AssertPremiumValues(BeazleyUIDataModel data, ValidationData vd)
        {
            vd.PolicyReference = jsonHelper.GetPolicyReference(data);
            vd.TestName = jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.TestName);

            AssertGrossPremium(vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.GrossPremium));
            AssertTaxAndFees(vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.Tax));
            AssertNetPremium(vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.NetPremium));
            AssertNetAmountPayable(vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.NetPremiumPayable));
            AssertTotalPremium(vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.TotalPremium));

            if (jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.TestType).Equals(HelperConstants.Correction))
            {
                AssertBusinessName(vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.InsuredName));
                AssertAddressLine(vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.AddressLine));
                AssertPostCode(vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.PostCode));
            }

            return vd;
        }

        public ValidationData AssertDates(BeazleyUIDataModel data, ValidationData vd)
        {
            vd.PolicyReference = jsonHelper.GetPolicyReference(data);
            vd.TestName = jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.TestName);

            AssertInceptionDate(vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.INCEPTION_DATE));
            AssertExpiryDate(vd, jsonHelper.GetValueDataFromBeazleyDictionary(data, HelperConstants.EXPIRY_DATE));

            return vd;
        }

        public void AssertInceptionDate(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetInceptionDate();

            if (unirisxValue.Contains(beazleyUIValue))
            {
                vd.Succes.Add($"PolicySummary Page: INCEPTION_DATE: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"PolicySummary Page: INCEPTION_DATE: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertExpiryDate(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetExpiryDate();

            if (unirisxValue.Contains(beazleyUIValue))
            {
                vd.Succes.Add($"PolicySummary Page: EXPIRY_DATE: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"PolicySummary Page: EXPIRY_DATE: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }


        public void AssertBusinessName(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetBusinessName();

            if (unirisxValue.Contains(beazleyUIValue))
            {
                vd.Succes.Add($"PolicySummary Page: Business Name: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"PolicySummary Page: Business Name: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertAddressLine(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetAddressLine();

            if (unirisxValue.Contains(beazleyUIValue))
            {
                vd.Succes.Add($"PolicySummary Page: Address Line: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"PolicySummary Page: Address Line: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertPostCode(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetPostCode();

            if (unirisxValue.Contains(beazleyUIValue))
            {
                vd.Succes.Add($"PolicySummary Page: PostCode: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"PolicySummary Page: PostCode: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }


        public void AssertGrossPremium(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetGrossPremium();

            if (CheckValueIsInRange(beazleyUIValue, unirisxValue))
            {
                vd.Succes.Add($"PolicySummary Page: Gross Premium: Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"PolicySummary Page: Gross Premium: Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertTaxAndFees(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetTaxAndFees();

            if (CheckValueIsInRange(beazleyUIValue, unirisxValue))
            {
                vd.Succes.Add($"PolicySummary Page: TaxAndFees : Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"PolicySummary Page: TaxAndFees : Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertNetPremium(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetNetPremium();

            if (CheckValueIsInRange(beazleyUIValue, unirisxValue))
            {
                vd.Succes.Add($"PolicySummary Page: NetPremium : Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"PolicySummary Page: NetPremium : Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertNetAmountPayable(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetNetAmountPayable();

            if (CheckValueIsInRange(beazleyUIValue, unirisxValue))
            {
                vd.Succes.Add($"PolicySummary Page: NetAmountPayable : Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"PolicySummary Page: NetAmountPayable : Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }

        public void AssertTotalPremium(ValidationData vd, string beazleyUIValue)
        {
            string unirisxValue = GetGrossAmountPayable();

            if (CheckValueIsInRange(beazleyUIValue, unirisxValue))
            {
                vd.Succes.Add($"PolicySummary Page: GrossAmountPayable : Passed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
            }
            else vd.Errors.Add($"PolicySummary Page: GrossAmountPayable : Failed / Unirisx Value: {unirisxValue} / Beazley UI Value: {beazleyUIValue}");
        }


        public string GetBusinessName()
        {
            var businessName = FindIWebElementByXPath("//tr[2]//tr/td[contains(text() , 'New Business Name')]");
            return GetInnerText(businessName);
        }

        public string GetAddressLine()
        {
            var addressLine = FindIWebElementByXPath("//td[2]/table/tbody/tr/td[contains(text() , 'New Address')]");
            return GetInnerText(addressLine);
        }

        public string GetPostCode()
        {
            var postCode = FindIWebElementByXPath("//td[2]/table/tbody/tr/td[contains(text() , 'New Address')]");
            return GetInnerText(postCode);
        }

        public string GetGrossPremium()
        {
            var grossPremium = FindIWebElementByXPath("//td[contains(text(),'Gross Premium')]/../td[2]");
            return GetInnerText(grossPremium).Split(' ')[0];
        }

        public string GetTaxAndFees()
        {
            var taxAndFees = FindIWebElementByXPath("//td[contains(text(),'Total Fees and Taxes')]/../td[2]");
            return GetInnerText(taxAndFees).Split(' ')[0];
        }

        public string GetNetPremium()
        {
            var netPremium = FindIWebElementByXPath("//td[contains(text(),'Net Premium')]/../td[2]");
            return GetInnerText(netPremium).Split(' ')[0];
        }

        public string GetNetAmountPayable()
        {
            var netAmountPayable = FindIWebElementByXPath("//td[contains(text(),'Net Amount Payable')]/../td[2]");
            return GetInnerText(netAmountPayable).Split(' ')[0];
        }

        public string GetGrossAmountPayable()
        {
            var grossAmountPayable = FindIWebElementByXPath("//td[contains(text(),'Gross Amount Payable')]/../td[2]");
            return GetInnerText(grossAmountPayable).Split(' ')[0];
        }


        public string GetInceptionDate()
        {
            var uiElement = FindIWebElementByXPath("//*[@id='chkListNB']/table/tbody/tr[2]/td/table/tbody/tr[2]/td[3]");
            return GetInnerText(uiElement);
        }

        public string GetExpiryDate()
        {
            var uiElement = FindIWebElementByXPath("//*[@id='chkListNB']/table/tbody/tr[2]/td/table/tbody/tr[2]/td[5]");
            return GetInnerText(uiElement);
        }


    }
}