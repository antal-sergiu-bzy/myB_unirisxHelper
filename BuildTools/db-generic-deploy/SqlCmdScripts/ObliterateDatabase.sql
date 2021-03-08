declare
   @vcFK varchar(250),
   @vcTable varchar(250),
   @vcSP varchar(250),
   @vcView varchar(250),
   @vcFn varchar(250)

-- ...drop all foreign key constraints      
select @vcFK = min(name) from sysobjects where type='F'
while @vcFK is not null
begin
   print 'Dropping FK constraint ' + @vcFK
   
   -- ...get name of table corresponding to the foreign key
   select
      @vcTable = S2.name
   from
      sysobjects S1
      inner join sysconstraints C on S1.id = C.constid
      inner join sysobjects S2 on C.id = S2.id
   where
      S1.name = @vcFK and S1.type='F'
   
   exec ('alter table ' + @vcTable + ' drop constraint ' + @vcFK)
   select @vcFK = min(name) from sysobjects where type='F' and name > @vcFK
end

-- ...drop all tables
select @vcTable = min(name) from sysobjects where type='U' and name not like 'dt%'
while @vcTable is not null
begin
   print 'Dropping table ' + @vcTable
   exec ('drop table ' + @vcTable)
   select @vcTable = min(name) from sysobjects where type='U' and name not like 'dt%' and name > @vcTable
end

-- ...drop all our stored procedures
select @vcSP = min(name) from sysobjects where type='P' and (name like 'usp%')
while @vcSP is not null
begin
   print 'Dropping procedure ' + @vcSP
   exec ('drop procedure ' + @vcSP)
   select @vcSP = min(name) from sysobjects where type='P' and (name like 'usp%') and name > @vcSP
end

-- ...drop all views
select @vcView = min(name) from sysobjects where type='V' and name like 'v%'
while @vcView is not null
begin
   print 'Dropping view ' + @vcView
   exec ('drop view ' + @vcView)
   select @vcView = min(name) from sysobjects where type='V' and name like 'v%' and name > @vcView
end
   
-- ...drop all functions
select @vcFn = min(name) from sysobjects where type='FN' and name like 'udf%'
while @vcFn is not null
begin
   print 'Dropping function ' + @vcFn
   exec ('drop function ' + @vcFn)
   select @vcFn = min(name) from sysobjects where type='FN' and name like 'udf%' and name > @vcFn
end