DECLARE @login_name SYSNAME, @environment_name NVARCHAR (3);

SELECT @environment_name = CAST([value] AS NVARCHAR(3)) FROM [master].[sys].[fn_listextendedproperty] (NULL, NULL, NULL, NULL, NULL, NULL, NULL) WHERE [name] = N'Environment Name';

IF ('$(suffix_style)' = 'ENV')
BEGIN
  -- Set Login [default]: Environment Specific (DEV)
  SET @login_name = N'$(login_domain)\$(user_name)_DEV';

  -- Set Login - based upon 'Environment Name' extended property on 'master' database
  IF (@environment_name IN ('PKG', 'PRD'))
    SET @login_name = N'$(login_domain)\$(user_name)_PRD';
  ELSE IF (NOT @environment_name IS NULL)
    SET @login_name = N'$(login_domain)\$(user_name)_' + @environment_name;
END;
ELSE IF ('$(suffix_style)' = 'TST')
BEGIN
  -- set @login_name (for non-production) [default]
  SET @login_name = N'BFL\$(user_name).TST';

  -- set @login_name (for production) based upon the 'Environment Name' extended property on 'master' database
  IF (@environment_name IN ('PKG', 'PRD'))
    SET @login_name = N'BFL\$(user_name)';
END;
ELSE IF ('$(suffix_style)' = 'NONE')
  SET @login_name = N'$(login_domain)\$(user_name)';
ELSE
  RAISERROR ('Invalid suffix style: $(suffix_style)', 15, 10);

IF (@environment_name IS NULL)
  RAISERROR ('Login "%s" used for user "$(user_name)" - no environment specific value [extended property].', 10, 1, @login_name);

IF (NOT EXISTS (SELECT 1 FROM [master].[sys].[server_principals] WHERE [name] = @login_name))
  RAISERROR ('Login "%s" does not exists to create user "$(user_name)"', 11, 1, @login_name);

PRINT '$(databaseName)';

USE [$(databaseName)];

EXECUTE('CREATE USER [$(user_name)] FOR LOGIN [' + @login_name +']');

DECLARE @server2008_ver DECIMAL = 10, @server_ver DECIMAL, @is_windows_group BIT
SELECT @server_ver = CAST(serverproperty('productversion') as VARCHAR(4)),
       @is_windows_group = isntgroup
FROM  master..syslogins
WHERE name = @login_name
-- Cannot add default schema for Windows groups for Server 2008 and below
IF (@server_ver > @server2008_ver OR @is_windows_group = 0)
  ALTER USER [$(user_name)] WITH DEFAULT_SCHEMA=[$(schema)];

GRANT CONNECT TO [$(user_name)];
