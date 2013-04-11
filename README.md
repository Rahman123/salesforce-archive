Data storage is calculated by Salesforce at roughly 2KB for each record. This utility provides a toolkit to archive your data using a smaller number of records, without losing relevant information.

## Features
* Keep your business' relevant data
* Free up to 94% of the data storage for unused records
* Ready to use batch classes for archiving/restoring data

## Limitations
* Only works if your records are smaller than 32k
* You won’t be able to use the archived information on Salesforce for any purpose until you restore
* You will lose all the readonly fields
* Does not support related objects

## Usage
Archive
> ArchiveStoreBatch storeBatch = new ArchiveStoreBatch('SELECT Id, ... FROM ...'); 
> Database.executeBatch(storeBatch); 

## Restore
> Archive__c archive = ... // Select your archive
> ArchiveRestoreBatch restoreBatch = new ArchiveRestoreBatch(archive); 
> Database.executeBatch(restoreBatch); 
