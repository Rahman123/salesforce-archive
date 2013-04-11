Data storage is calculated by Salesforce at roughly 2KB for each record. This utility provides a toolkit to archive your data using a smaller number of records, without losing relevant information.

## Features
* Free up to 94% of the data storage for unused records
* Ready to use batch classes for archiving/restoring data
* Automatically sends an email when the task is completed

## Limitations
* Only works if your records are smaller than 32k
* You won’t be able to use the archived information on Salesforce for any purpose until you restore
* You will lose all the readonly fields
* Does not support related objects

## Usage
### Archive
> ArchiveStoreBatch storeBatch = new ArchiveStoreBatch('SELECT Id, ... FROM ...'); <br/>
> Database.executeBatch(storeBatch);

### Restore
> Archive__c archive = ... // select your archive <br/>
> ArchiveRestoreBatch restoreBatch = new ArchiveRestoreBatch(archive); <br/>
> Database.executeBatch(restoreBatch); 
