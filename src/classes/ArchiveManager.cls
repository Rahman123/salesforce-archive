public with sharing class ArchiveManager {
	
	final static Integer STORAGE_CHAR_LIMIT = 32768;

	public static List<sObject> restore(List<Archive_Entry__c> entries) {
		if (entries!=null && entries.size()>0) {
			List<sObject> restoredItems = new List<sObject>();
			List<sObject> toInsert = new List<sObject>();
			for (Archive_Entry__c entry:entries) {
				System.Type pType = System.Type.forName('List<' + entry.Object_Type__c + '>');
				List<sObject> items = (List<sObject>) ArchiveSerializer.deserialize(entry.Stored_Data__c, pType);
				for (sObject item:items) {
					restoredItems.add(item);
					toInsert.add(item);
				}
			}
			insert toInsert;
			delete entries;
			return restoredItems;
		}
		return null;
	}	
	
	public static List<Archive_Entry__c> archive(List<sObject> items, Archive__c archive) {
		List<Archive_Entry__c> toBeArchived = new List<Archive_Entry__c>(); 
		List<sObject> toBeDeleted = new List<sObject>(); 	// only successfully archived items will be deleted
		
		// Check the first item to analyze the type, and the chunkSize and do stuff
		sObject firstItem = items[0];
		String firstSerialized = ArchiveSerializer.serialize(firstItem);
		Integer jsonOverhead = (items.size() - 1) + 2; 		// commas between elements + {brackets}
		Integer elementSize = firstSerialized.length() > 0 ? firstSerialized.length() : 1; 
		Integer chunkSize = (STORAGE_CHAR_LIMIT-jsonOverhead) / elementSize;	// size in bytes of for single element 
		Integer nChunks = (1+(items.size()/chunkSize)); 	// number of expected chunks
		
		if (chunkSize>0) {
			Integer processed = 0;
			Integer left = items.size() - processed;
			Integer chunkCount = 0;
			do {
				chunkCount++;
				List<sObject> chunk = new List<sObject>();
				while ( left>0 && chunk.size()< chunkSize ) {
					chunk.add(items.get(processed));
					processed++;
					left = items.size() - processed;
				}
				
				// Chunk is ready, create serialized entry...
								
				String serialized = ArchiveSerializer.serialize(chunk);
				if (serialized.length()<=STORAGE_CHAR_LIMIT) {
					String objectTypeStr = '' + firstItem.getSObjectType();
					Archive_Entry__c entry = new Archive_Entry__c();
					entry.Object_Type__c  =  objectTypeStr;
					entry.Stored_Data__c =  serialized;
					entry.Archive__c = archive.id;
					toBeArchived.add(entry);
				} else {
					// if serialized entry is too big it is just skipped
				}
				
			} while ( processed < items.size() );
		}

		insert toBeArchived; 	// save compressed entries
		delete toBeDeleted; 	// remove originals
		
		// Log compression report 
		Decimal oSize = Decimal.valueOf(toBeDeleted.size());
		Decimal cSize = Decimal.valueOf(toBeArchived.size());
		List<Archive__c> archives = [SELECT Id, Records_archived__c, Records_used__c,Compression_Ratio__c, Status__c FROM Archive__c WHERE Id = :archive.Id LIMIT 1];
		if (archives.size()==1) {
			archive = archives[0];
			Decimal alreadyArchived = (archive.Records_archived__c!=null) ? archive.Records_archived__c : 0; 
			Decimal alreadyUsed = (archive.Records_used__c!=null) ? archive.Records_used__c : 0;
			archive.Records_archived__c = alreadyArchived + oSize;
			archive.Records_used__c = alreadyUsed + cSize;
			update archive;
		}
		return toBeArchived;
	}

}