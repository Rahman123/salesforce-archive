public with sharing class ArchiveSerializer {
	
	private final static String ID_PLACEHOLDER = '?ID_PLACEHOLDER?';
	private final static List<String> fieldsToReset = new List<String>{'CreatedById','OwnerId','LastModifiedById'};
	
	public static String serialize(Object pObject) {
		String serialized = JSON.serialize(pObject);
		for (String fieldName : fieldsToReset) {
			Pattern idRegex = Pattern.compile('"'+fieldName+'":"([a-zA-Z0-9]{15}|[a-zA-Z0-9]{18})"');
			serialized = idRegex.matcher(serialized).replaceAll('"'+fieldName+'":'+ID_PLACEHOLDER);
		}
		Pattern idRegex = Pattern.compile('"Id":"([a-zA-Z0-9]{15}|[a-zA-Z0-9]{18})"');
		serialized = idRegex.matcher(serialized).replaceAll('"Id":null');
		return serialized;
	}
	
	public static Object deserialize(String pString, System.Type pType) {
		pString = pString.replace(ID_PLACEHOLDER, '"' + UserInfo.getUserId() + '"'); 
		return JSON.deserialize(pString, pType);
	}

}