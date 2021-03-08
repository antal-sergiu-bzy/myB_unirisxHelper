DECLARE @createScript NVARCHAR(MAX);

IF NOT EXISTS (SELECT * FROM master.dbo.sysdatabases WHERE name = N'$(DatabaseName)')
BEGIN
    SET @createScript = 'CREATE DATABASE $(DatabaseName)';

    IF (N'$(Collation)' <> N'$' + N'(Collation)')
      SET @createScript = @createScript + ' COLLATE $(Collation)';

    SET @createScript = @createScript + ';';

    EXECUTE sp_executesql @createScript;

    IF (N'$(CompatibilityLevel)' <> N'$' + N'(CompatibilityLevel)'
      AND (
        SELECT compatibility_level
        FROM sys.databases
        WHERE name = N'$(DatabaseName)'
      ) <> N'$(CompatibilityLevel)'
    )
      EXECUTE sp_executesql N'
        ALTER DATABASE $(DatabaseName)
        SET COMPATIBILITY_LEVEL = $(CompatibilityLevel);';
END;
GO
