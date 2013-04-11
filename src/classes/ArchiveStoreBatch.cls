global with sharing class ArchiveStoreBatch implements Database.Batchable<sObject> {
	
	private Archive__c archive {get; set;}
	private String soqlQuery {get; set;}
	
	public ArchiveStoreBatch(Archive__c pArchive, String soqlQuery) {
		this.archive = pArchive;
		this.soqlQuery = soqlQuery;
	} 
	
	global Database.querylocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(soqlQuery);
	}
		
	global void execute(Database.BatchableContext BC, List<sObject> items) {
		ArchiveManager.archive(items, archive);
	}
	
	global void finish(Database.BatchableContext BC) {
		List<Archive__c> items = [SELECT Status__c,Compression_Ratio__c,Id,Records_archived__c,Records_used__c FROM Archive__c WHERE Id=:archive.Id LIMIT 1];
		if (items.size()==1) {
			archive = items[0];
		}
		if (archive.Records_archived__c>0) {
			
			// Batch completed
			archive.Status__c = 'Ready';
			update archive;
			
			AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id =:BC.getJobId()];
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] {a.CreatedBy.Email};
			mail.setToAddresses(toAddresses);
			mail.setSubject('Archive successfully created');
			mail.setPlainTextBody('Your records have been archived successfully.' + archive.Records_archived__c + ' records were archived with an overall ' + archive.Compression_Ratio__c + '% compression ratio.');
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			
		} else {
			delete archive; // nothing archived, delete the archive
			
			AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id =:BC.getJobId()];
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] {a.CreatedBy.Email};
			mail.setToAddresses(toAddresses);
			mail.setSubject('Archive creation failed');
			mail.setPlainTextBody('The archive operation has been aborted. This means that either the selection was empty or your records were too big to be archived.');
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
	}

}