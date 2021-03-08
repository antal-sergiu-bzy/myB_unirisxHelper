/*

	This script is run as part of the DB Ghost database synchronization/comparison process.
	This script is run before any changes are made to the target database. That is before the comparison is made between the database
	created using the object scripts, and the target database.
	It must be repeatable as it will always run on every process.
	
	In most cases there is no requirement for this script.
	This script is in existance so that if a requirement does emerge, then the developer only needs to change this script and it will be
	run as the DB Ghost configuration files will have a reference to it and it will be run on every process.
	
	You could use this script to perform re-factoring, as an example.
	Let us say that you have a single table which requires normalization and will be split into two tables.
	If the comparison was made between the database built from scripts and the target database, you would see an extra table and two new tables.
	This can lead to the software dropping the extra table and creating two new tables, resulting in the loss of data. It will do this 
	as there is no way it can determine what else is required - it simply looks like an extra table and two new tables.
	This custom script gives you, the developer the ability to customize the process.
	In the example you would do the following:
	
	If not exists(old table)
	begin
	
		create new table 1
		create new table 2
		
		insert values from old table into new table 1
		insert values from old table into new table 2
		
		drop old table
		
	end
	
	The logic means the script is repeatable, it will perform the action only once.
	The create table statements should be kept simple, there is no need to add fks, pks, uqs, triggers - any child object of the table as 
	DB Ghost will find these missing and create them where required. 
*/