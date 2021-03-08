using System.Collections;
using System.Collections.Generic;
using System.Linq;
using TechTalk.JiraRestClient;
using System.Collections.Concurrent;
using ScriptCs.Beazley.ReleaseNotes;

var releaseNotesGenerator = Require<ReleaseNotesGenerator>();
var options = new GenerationOptions{
    Organization = System.Environment.GetEnvironmentVariable("GIT_ORGANIZATION"),
    Repo = System.Environment.GetEnvironmentVariable("GIT_REPOSITORY"),
    BaseRef = Env.ScriptArgs[2],
    HeadRef = System.Environment.GetEnvironmentVariable("BUILD_VCS_NUMBER"),
    BuildLabel = Env.ScriptArgs[0],
    JiraPrefix = System.Environment.GetEnvironmentVariable("JIRA_PREFIX")
};

if(Env.ScriptArgs.Count() > 1)
{
  options.ReleaseNotesMdPath = Env.ScriptArgs[1];
}

releaseNotesGenerator.Generate(options);
