db-generic-deploy
=================

Generic DB deployment package

Template DB Creation
--------------------
Multiple Template database creation mechanisms are supported

Project settings are configured in `DbSettings.psd1`

Schemaster Settings (default)
-----------------------------
[Example Usage (DocVault)](http://git.bfl.local/DocVault/MetaStore/tree/master/Database/Deployment/DocVault)
 

```powershell
@{
  users=@(
    @{
      domain='bfl'
      userName='SVC_BzDocTales'
      suffixStyle='env'
      roles=@{
        DocTale=@('Reader','Upserter','Deleter','Execer','    DefinitionViewer')
      }
    }
  )
  components=@('DocTales')
  createScripts=@{
    DocVault=@('CreateSchema')
  }
}
```

Entity Framework Settings
-------------------------
[Example Usage (WIN)](http://git.bfl.local/Beazley/Beazley.WIN/tree/master/deployment/database)

```powershell
@{
  deploymentSettings=@{
    type='EntityFramework'
    schemaAssembly='Beazley.Foo.Data.dll'
  }
  users=@(
    @{
      domain='bfl'
      userName='SVC_BzFooWeb'
      suffixStyle='env'
      roles= @('db_datareader','db_datawriter')
      grants=@('exec')
    }
  )
}

```

SSDT Settings
-------------
[Example Usage (FTS)](http://git.bfl.local/Beazley/FinancialTransactionService)

```powershell

@{
  deploymentSettings=@{
    type='SSDT'
    dacPac='Beazley.Schema.FooBar.dacpac'
  }
  users=@(
    @{
      domain='bfl'
      userName='SVC_BzFooWeb'
      suffixStyle='env'
      roles= @('db_datareader','db_datawriter')
      grants=@('exec')
    },
    @{
      domain='bfl'
      userName='DBS.SQL.Foo.RO'
      suffixStyle='tst'
      roles=@('db_datareader')
      grants=@('view definition')
    }
  )
}

```

DB Ghost Settings
-----------------
[Example Usage (BeazleyPro_RMI)](http://git.bfl.local/Beazley/BeazleyPro_RMI)

```powershell
@{
  users=@(
    @{
      domain='bfl'
      userName='DBS.SQL.BeazleyPro_RMI_Data.RO'
      suffixStyle='tst'
    },
    @{
      domain='bfl'
      userName='BeazleyDataServices'
      suffixStyle='none'
    }
  )
  deploymentSettings = @{
    type = 'DbGhost'
  }
}
```
