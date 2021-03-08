require 'rake/clean'
require 'fileutils'
require 'io/console'

#--------------------------------------
# Variables
#--------------------------------------
SONARQUBE_PROJECT_KEY = (ENV['SONARQUBE_PROJECT_KEY']).to_s || SONARQUBE_PROJECT_KEY

#--------------------------------------
# SONARQUBE SCANNER TASK
#--------------------------------------

task :sonarqube_scanner, %i[build_number msbuild_config] => \
                         %i[sonarqube_scanner_begin build opencover_scanner sonarqube_scanner_end]

exec :sonarqube_scanner_begin, %i[build_number] do |cmd, args|
  puts 'Starting SonarQube Scanner Engine'
  cmd.working_directory = SOLUTION_DIR
  cmd.command = 'SonarScanner.MSBuild.exe'
  if defined? KARMA_JASMINE_REPORT # rubocop:disable Style/ConditionalAssignment
    cmd.parameters = [
      'begin',
      "/k:#{SONARQUBE_PROJECT_KEY}",
      "/v:#{args.build_number}",
      "/d:sonar.cs.nunit.reportsPaths=#{SOLUTION_DIR}\\TestResult.xml",
      "/d:sonar.cs.opencover.reportsPaths=#{SOLUTION_DIR}\\opencover.xml",
      "/d:sonar.javascript.lcov.reportPaths=#{SOLUTION_DIR}\\lcov.info",
      "/d:sonar.testExecutionReportPaths=#{SOLUTION_DIR}\\#{KARMA_JASMINE_REPORT}"
    ]
  else
    cmd.parameters = [
      'begin',
      "/k:#{SONARQUBE_PROJECT_KEY}",
      "/v:#{args.build_number}",
      "/d:sonar.cs.nunit.reportsPaths=#{SOLUTION_DIR}\\TestResult.xml",
      "/d:sonar.cs.opencover.reportsPaths=#{SOLUTION_DIR}\\opencover.xml",
      "/d:sonar.javascript.lcov.reportPaths=#{SOLUTION_DIR}\\lcov.info"
    ]
  end
end

exec :sonarqube_scanner_end do |cmd, _args|
  puts 'Complete SonarQube analysis'
  cmd.working_directory = SOLUTION_DIR
  cmd.command = 'SonarScanner.MSBuild.exe'
  cmd.parameters = [
    'end'
  ]
end

exec :opencover_scanner do |cmd|
  puts 'Opencover Scanner'
  if defined? NUNIT_ASSEMBLIES
    runner_dir = File.join(get_runner_directory, 'tools', 'nunit3-console.exe')
    cmd.working_directory = SOLUTION_DIR
    cmd.command = 'OpenCover.Console.exe'
    cmd.parameters = [
      "-target:#{runner_dir}",
      "-targetargs:\"#{NUNIT_ASSEMBLIES}\"",
      '-filter:+[*]*',
      "-output:#{SOLUTION_DIR}\\opencover.xml"
    ]
  else
    cmd.command = 'echo'
    cmd.parameters = [
      'not Nunit Assemblies defined'
    ]
  end
end
