PRINT '$(databaseName)';

USE [$(databaseName)];

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$(user)')
  RAISERROR ('Cannot add role "$(role)" to non-existent user "$(user)".', 11, 1);

EXEC sp_addrolemember N'$(role)', [$(user)];
