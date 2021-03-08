using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace myBeazley.UnirisxHelper.DataTransferObj.UISerialization
{
    public class JsonHelper
    {
        private static List<string> GetFoldersPathInUnirisxRoot()
        {
            string rootPath = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            string UnirisxJsonsPath = rootPath + @"\Unirisx_Jsons";

            return System.IO.Directory.GetDirectories(UnirisxJsonsPath).ToList();
        }

        public static string GetJsonFile(int index = -1)
        {
            var folders = GetFoldersPathInUnirisxRoot();

            if (!index.Equals(-1)) return folders[index];
            return folders.Last();
        }

        public static string CreateAndRetrieveResultsFilePath(string phaseNo)
        {
            var serializedJsonPath = GetJsonFile();
            return serializedJsonPath + @"\results_Phase" + $"{phaseNo}.txt";
        }

        public static string CreateAndRetrieveNewJsonPath(BeazleyUIDataModel model)
        {
            string rootPath = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            string UnirisxJsonsPath = rootPath + @"\Unirisx_Jsons";

            string jsonPath = UnirisxJsonsPath +
                              @"\" + DateTime.Now.Day + "_" + DateTime.Now.Month + "_" + DateTime.Now.Year + "_" + DateTime.Now.ToLongTimeString().Replace(":", "_");

            var directoryInfo = System.IO.Directory.CreateDirectory(jsonPath);

            return directoryInfo.FullName;
        }

        public void SerializeJson(List<BeazleyUIDataModel> data, string path)
        {
            var phaseNo = GetValueDataFromBeazleyDictionary(data.First(), HelperConstants.PhaseNo);

            if (!phaseNo.Equals("1")) path = GetJsonFile();

            using (var fileWriter = new StreamWriter(path + @"\serialized_Phase" + $"{phaseNo}.json"))
            {
                var serializedString = JsonConvert.SerializeObject(data);
                fileWriter.Write(serializedString);
            }
        }

        public List<BeazleyUIDataModel> DeserializeJson(string path, string phaseNo)
        {
            List<BeazleyUIDataModel> deserializedObjectList = null;
            FileStream filePathToRead = File.OpenRead(path + @"\serialized_Phase" + $"{phaseNo}.json");
            using (var streamReader = new StreamReader(filePathToRead))
            {
                string content = streamReader.ReadToEnd();
                deserializedObjectList = JsonConvert.DeserializeObject<List<BeazleyUIDataModel>>(content);
            }

            return deserializedObjectList;
        }


        #region JSON Getters Composed

        public string GetInsuredNameByPolicyReference(List<BeazleyUIDataModel> listOfData, string policyReference)
        {
            string insuredName = "NOT FOUND";

            foreach (var data in listOfData)
            {
                if (GetPolicyReference(data).Equals(policyReference))
                {
                    var policyDetails = data.PolicyDetails.First();
                    var policyDetail = policyDetails.Value;
                    foreach (var keyvaluePair in policyDetail.DataFromBeazley)
                    {
                        if (keyvaluePair.Key.Equals(HelperConstants.InsuredName))
                        {
                            insuredName = keyvaluePair.Value;
                            break;
                        }
                    }
                }
            }
            return insuredName;
        }


        public string GetTestNameByPolicyReference(List<BeazleyUIDataModel> listOfData, string policyReference)
        {
            string testName = "NOT FOUND";

            foreach (var data in listOfData)
            {
                if (GetPolicyReference(data).Equals(policyReference))
                {
                    var policyDetails = data.PolicyDetails.First();
                    var policyDetail = policyDetails.Value;
                    foreach (var keyvaluePair in policyDetail.DataFromBeazley)
                    {
                        if (keyvaluePair.Key.Equals(HelperConstants.TestName))
                        {
                            testName = keyvaluePair.Value;
                            break;
                        }
                    }
                }
            }
            return testName;
        }

        public string GetPolicyReferenceByScenarioDescription(List<BeazleyUIDataModel> listOfData, string desc)
        {
            string policyRef = "NOT FOUND";

            foreach (var data in listOfData)
            {
                var policyDetails = data.PolicyDetails.First();
                var policyDetail = policyDetails.Value;
                foreach (var keyvaluePair in policyDetail.DataFromBeazley)
                {
                    if (keyvaluePair.Key.Equals(HelperConstants.TestDescription) && keyvaluePair.Value.Equals(desc))
                    {
                        policyRef = GetPolicyReference(data);
                        break;
                    }
                }
            }
            return policyRef;
        }

        public string GetCommissionNameByPolicyReference(List<BeazleyUIDataModel> listOfData, string policyReference)
        {
            string commission = "NOT FOUND";

            foreach (var data in listOfData)
            {
                if (GetPolicyReference(data).Equals(policyReference))
                {
                    var policyDetails = data.PolicyDetails.First();
                    var policyDetail = policyDetails.Value;
                    foreach (var keyvaluePair in policyDetail.DataFromBeazley)
                    {
                        if (keyvaluePair.Key.Equals(HelperConstants.CommissionPercentage))
                        {
                            commission = keyvaluePair.Value;
                            break;
                        }
                    }
                }
            }
            return commission;
        }

        public string GetPolicyReference(BeazleyUIDataModel data)
        {
            return data.PolicyDetails.Keys.First();
        }

        #endregion


        #region Getter for DataFromBeazleyDictionary Values

        public string GetValueDataFromBeazleyDictionary(BeazleyUIDataModel data, string valueToSerach)
        {
            string result = "NOT FOUND";
            var policyDetails = data.PolicyDetails.First();
            var policyDetail = policyDetails.Value;

            foreach (var keyvaluePair in policyDetail.DataFromBeazley)
            {
                if (keyvaluePair.Key.Equals(valueToSerach))
                {
                    result = keyvaluePair.Value;
                    break;
                }
            }
            return result;
        }


        #endregion
    }
}
