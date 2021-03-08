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
  SET @login_name = N'$(login_domain)\$(user_name).TST';

  -- set @login_name (for production) based upon the 'Environment Name' extended property on 'master' database
  IF (@environment_name IN ('PKG', 'PRD'))
    SET @login_name = N'$(login_domain)\$(user_name)';
END;
ELSE IF ('$(suffix_style)' = 'NONE')
  SET @login_name = N'$(login_domain)\$(user_name)';
ELSE
  RAISERROR ('Invalid suffix style: $(suffix_style)', 15, 10);

IF (@environment_name IS NULL)
  RAISERROR ('Login "%s" used - no environment specific value [extended property].', 10, 1, @login_name);

IF (EXISTS (SELECT 1 FROM [master].[sys].[server_principals] WHERE [name] = @login_name))
  RAISERROR ('Login "%s" already exists.', 10, 1, @login_name);
ELSE
BEGIN
  EXECUTE ('CREATE LOGIN [' + @login_name + '] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]');
  RAISERROR ('Login "%s" created.', 10, 1, @login_name);
END;
