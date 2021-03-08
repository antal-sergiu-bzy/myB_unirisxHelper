/*

	This script is run as part of the DB Ghost database synchronization/comparison process.
	This script is run after any changes are made to the target database. That is after the comparison is made between the database
	created using the object scripts, and the target database.
	It must be repeatable as it will always run on every process.
	
	In most cases there is no requirement for this script.
	This script is in existance so that if a requirement does emerge, then the developer only needs to change this script and it will be
	run as the DB Ghost configuration files will have a reference to it and it will be run on every process.
	
*/