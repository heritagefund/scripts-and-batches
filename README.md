# Scripts and batches
This is a repository for the storage of automation scripts and batch job instruction used for data zaps. 

Scripts are as follows:

## Forty Perc Zap

This script will run zaps against a Postgres instance deployed on GovPaas, using the `Conduit` Cloud Foundary plugin provided by gov-alpha. The script executes queries to add a 40% payment request to an applications, simulating a completed M1 40% Journey.

The details of the payment requests to be created and applications to be zapped are shored and read from a CSV files in the same directory as the script. 
Each CSV line contains the following columns which are then passed into the SQL queries to be executed:

- 40% payment amount (the payment amount requested)
- ApplicationId (ID of application to zap)
- Case id (Salesforce Case ID of app)
- Form id (ID of payment request form manually created)

 BEFORE RUNNING PLEASE NOTE:
  - On each line of query execution, the database name stated after the conduit cmd should be modified to the appropriate DB name (i.e. cf conduit [DB-NAME] --local-port 7081 -- psql -t -c "QUERY"")
  - The -s flag on the login cmd should be modified to point at the correct environnement in which the target DB is situated.
