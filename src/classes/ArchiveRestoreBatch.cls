global with sharing class ArchiveRestoreBatch implements Database.Batchable<sObject> {

	private Archive__c archive {get; set;}
	private String archiveId {get; set;}
	
	public ArchiveRestoreBatch(Archive__c pArchive) {
		archive = pArchive;
		archiveId = pArchive.Id;
	}
	
	global Database.querylocator start(Database.BatchableContext BC) {
		List<Archive__c> items = [SELECT Status__c,Compression_Ratio__c,Id,Records_archived__c,Records_used__c FROM Archive__c WHERE Id=:archive.Id LIMIT 1];
		if (items.size()==1) {
			archive = items[0];
		}
		archive.Status__c = 'Restoring';
		update archive;
		return Database.getQueryLocator('SELECT Id,Archive__r.Id,Object_Type__c,Stored_Data__c FROM Archive_Entry__c WHERE Archive__r.id = :archiveId');
	}
	
	global void execute(Database.BatchableContext BC, List<sObject> items) {
		ArchiveManager.restore(items);
	}
	
	global void finish(Database.BatchableContext BC) {
		// LogUtils.log('Restored records of compression ' + compression.Id);
		// LogUtils.log('The restore batch completed. Successfully extracted '+ compression.Records_archived__c+ ' records with a rate of ' + compression.Compression_Ratio__c);
		
		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id =:BC.getJobId()];
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {a.CreatedBy.Email};
		mail.setToAddresses(toAddresses);
		mail.setSubject('Records restore completed');
		mail.setPlainTextBody('The batch decompression completed successfully and restored ' + archive.Records_archived__c + ' records');
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		
		delete archive;
	}

}