PRINT 'Granting login to: $(LoginName)...'
EXEC sp_grantlogin '$(LoginName)'
GO
USE $(DatabaseName)
GO
PRINT 'Creating user: $(LoginName) for $(DatabaseName)...'
CREATE USER [$(LoginName)] FOR LOGIN [$(LoginName)]
GO
PRINT 'Making $(LoginName) a db_datareader...'
EXEC sp_addrolemember db_datareader, '$(LoginName)'
GO
PRINT 'Making $(LoginName) a db_datawriter...'
EXEC sp_addrolemember db_datawriter, '$(LoginName)'
GO
PRINT '$(LoginName) setup for $(DatabaseName)'