using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace myBeazley.UnirisxHelper.DataTransferObj.UISerialization
{
    public static class HelperConstants
    {

        #region General Details
        public static string RowNumberToCheck = "RowNumberToCheck";
        public static string InsuredName = "InsuredName";
        public static string TestName = "TestName";
        public static string TestDescription = "TestDescription";
        public static string PhaseNo = "PhaseNo";
        public static string TestType = "TestType";
        #endregion

        #region Premium properties
        public static string GrossPremium = "GrossPremium";
        public static string NetPremium = "NetPremium";
        public static string NetPremiumPayable = "NetPremiumPayable";
        public static string Tax = "Tax";
        public static string TotalPremium = "TotalPremium";
        public static string Commission = "Commission";
        public static string CommissionPercentage = "CommissionPercentage";
        #endregion

        #region TestTypes
        public static string Nb = "Nb";
        public static string Correction = "Correction";
        public static string MTA = "MTA";
        public static string Renewal = "Renewal";
        public static string Cancellation = "Cancellation";
        #endregion

        #region Only for Correction 
        public static string AddressLine = "AddressLine";
        public static string PostCode = "PostCode";
        #endregion

        #region Brexit Testing
        public static string IsBrexit = "IsBrexit";
        public static string UNDERWRITING_PLATFORM_SCPY = "SCPY - Service Company on behalf of Syndicate";
        public static string UNDERWRITING_PLATFORM_SLBS = "SLBS  - Service Company on behalf of Lloyd's Brussels";
        public static string SERIVCE_COMPANY_CODE_BSOL = "BSOL - Beazley Solutions Ltd";
        public static string SERIVCE_COMPANY_CODE_BSIL = "BSIL - Beazley Solutions International Limited";

        public static string COB_CODE = "COB_CODE";
        public static string TRI_FOCUS = "TRI_FOCUS";
        public static string STAT_CODE = "STAT_CODE";
        public static string RISK_CODE = "RISK_CODE";
        public static string SERIVCE_COMPANY_CODE = "SERIVCE_COMPANY_CODE";
        public static string UNDERWRITING_PLATFORM = "UNDERWRITING_PLATFORM";
        public static string BINDER_REFERENCE = "BINDER_REFERENCE";
        public static string UMR = "UMR";

        public static string INCEPTION_DATE = "INCEPTION_DATE";
        public static string EXPIRY_DATE = "EXPIRY_DATE";
        #endregion


        #region Default String Brexit MARINE
        public static string Marine_COB_CODE = "WH";
        public static string Marine_STAT_CODE = "83 – PLEASURE CRAFT";
        public static string Marine_RISK_CODE = "O";
        public static string Marine_TRI_FOCUS = "HULL";
        public static string Marine_BINDER_REFERENCE_BSOL = "B8121G21ANWH";
        public static string Marine_UMR_BSOL = "B6111YAC21WH";
        public static string Marine_BINDER_REFERENCE_BSIL = "B7572X21QNWH";
        public static string Marine_UMR_BSIL = "B6112BSFR21";
        #endregion


        #region Porduct Names
        public static string MedMal_Aesthetic = "MedMal Aesthetic";
        public static string MedMal_AestheticBrokerPortal = "MedMal AestheticBrokerPortal";
        public static string MedMal_AestheticNonLicensedPractitioner = "MedMal AestheticNonLicensedPractitioner";
        public static string MedMal_AlliedHealthcare = "MedMal AlliedHealthcare";
        public static string MedMal_BSDHT = "MedMal BSDHT";
        public static string MedMal_Boots = "MedMal Boots";
        public static string MedMal_Dental = "MedMal Dental";
        public static string MedMal_OpenMarket = "MedMal OpenMarket";
        public static string MedMal_VantageAesthetic = "MedMal VantageAesthetic";

        #endregion

        #region Rate Report Change
        public static string RateChange = "RateChange";
        public static string ExcessChange = "ExcessChange";
        public static string SumInsuredChange = "SumInsuredChange";
        public static string OtherChanges = "OtherChanges";
        public static string RiskAdjChange = "RiskAdjChange";

        #endregion
    }
}
