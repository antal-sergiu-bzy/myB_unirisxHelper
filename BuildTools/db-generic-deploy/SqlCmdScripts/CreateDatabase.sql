DECLARE @login_name SYSNAME

IF NOT EXISTS (SELECT [name] FROM [master].[sys].[databases] WHERE [name] = '$(DatabaseName)')
BEGIN
    EXECUTE ('CREATE DATABASE [$(DatabaseName)] COLLATE Latin1_General_CI_AS')
    EXECUTE ('ALTER DATABASE  [$(DatabaseName)] SET RECOVERY FULL')
    EXECUTE ('ALTER DATABASE  [$(DatabaseName)] MODIFY FILE ( NAME = ''$(DatabaseName)'', '
          +'SIZE = 50MB, FILEGROWTH = 50MB)')
    EXECUTE ('ALTER DATABASE  [$(DatabaseName)] MODIFY FILE ( NAME = ''$(DatabaseName)_log'', '
          +'SIZE = 50MB, FILEGROWTH = 128MB)')
          
    -- Previously this ran always but only run on create due to potential for read-only replicas
    SELECT @login_name = [loginname] FROM [master].[sys].[syslogins] WHERE [sid] = 0x01
    EXECUTE ('EXECUTE [$(DatabaseName)].[sys].[sp_changedbowner] @loginame=' + @login_name)
END
