public class PNNL_CopyAttachment {
  public static string clonedOppty;

  @InvocableMethod
  public static void CopyAttachment(List<List<Id>> opptyIds) {
    clone_opptyAttachments(opptyIds);
  }

  public static void clone_opptyAttachments(List<List<Id>> opptyIds) {
    //System.debug('Original Opty: ' + opptyIds[0][0]);
    string opptyId = opptyIds[0][0];
    //System.debug('Cloned Opty: ' + opptyIds[0][1]);
    string clonedOppty = opptyIds[0][1];
    Set<Id> ContentDocumentIds = new Set<Id>();
    ContentDocumentLink[] cdls = new List<ContentDocumentLink>();
    List<Opportunity_Attachment__c> attchList = new List<Opportunity_Attachment__c>();

    Map<Id, Opportunity_Attachment__c> oppAttachItems = new Map<Id, Opportunity_Attachment__c>(
      [
        SELECT
          Id,
          Name,
          Funding_Type__c,
          Attachment_Type__c,
          RecordTypeId,
          Opportunity__c,
          AttachmentId__c
        FROM Opportunity_Attachment__c
        WHERE Opportunity__c = :opptyId
      ]
    );

    if (oppAttachItems.isEmpty()) {
      //System.debug('No Attachments to copy.');
      return;
    }

    // loop at the attachment list and place content document records in a list
    for (Opportunity_Attachment__c attachmentRecord : oppAttachItems.values()) {
      //System.debug('Attachment Id is : ' + attachmentRecord.AttachmentId__c);
      ContentDocumentIds.add(attachmentRecord.AttachmentId__c);
    }
    //System.debug('ContentDocumentIds: ' + ContentDocumentIds);
    Map<Id, ContentVersion> versionItem = new Map<Id, ContentVersion>(
      [
        SELECT fields(standard)
        FROM ContentVersion
        WHERE
          IsLatest = TRUE
          AND IsDeleted = FALSE
          AND ContentDocumentId IN :ContentDocumentIds
      ]
    );

    if (versionItem.isEmpty()) {
      //System.debug('No Content Version Records found for the attachment file.');
      return;
    }

    //debugging only
    /*
System.debug('Looping through the content version Map');
for (Id cvId : versionItem.keySet()){
System.debug('version record: '+ versionItem.get(cvId));
}
*/

    for (Opportunity_Attachment__c attachment : oppAttachItems.values()) {
      //	Clone Attachment Record
      Opportunity_Attachment__c oppAttachClone = attachment.clone(
        false,
        true,
        false,
        false
      );
      oppAttachClone.Opportunity__c = clonedOppty;
      attchList.add(oppAttachClone);
    }
    // insert the list of attachment records
    insert attchList;

    //loop over newly created attachments and update the attachment_id field
    for (Opportunity_Attachment__c attachment : attchList) {
      //System.debug('ContentDocumentIds: ' + ContentDocumentIds);
      //loop over version records to find the one where contentdocumentid = attachmentId__c
      //
      for (ContentVersion cv : versionItem.values()) {
        //System.debug('version record: ' + cv);
        if (cv.contentdocumentid == attachment.AttachmentId__c) {
          //found the record.
          //
          ContentVersion versionNew = new ContentVersion(
            VersionData = cv.VersionData,
            Title = cv.Title,
            ContentUrl = cv.ContentUrl,
            PathOnClient = cv.PathOnClient
          );
          insert versionNew;
          //System.debug('Number of DML statements used so far : ' + Limits.getDmlStatements());
          //system.debug('VersionNew Id value: ' + versionNew.Id);
          ContentVersion versionNewQueried = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :versionNew.Id
            LIMIT 1
          ];
          cdls.add(
            new ContentDocumentLink(
              LinkedEntityId = attachment.Id,
              ContentDocumentId = versionNewQueried.ContentDocumentId
            )
          );
          attachment.AttachmentId__c = versionNewQueried.ContentDocumentId;
          //break out of the loop
          break;
        }
      }
    }
    //update the attachment list with new content document id ids
    update attchList;
    //insert the document link items to associate the new file to the opportunity
    insert cdls;

    //for debugging only
    /*  
* for (ContentDocumentLink cdl : docLinkItems){
system.debug('The original doclinkedItems:');
system.debug(cdl);
}

for (Opportunity_Attachment__c newCloneAttachment: [select id, name from Opportunity_Attachment__c where id IN :attchList]){
system.debug('This is the new list of attachments: '+ newCloneAttachment);
}

for (ContentVersion cv: versionItem){
system.debug('Looping through the contentversion records: '+cv);
}

    System.debug(
      'Final number of script statements used : ' + Limits.getDmlStatements()
    );
    System.debug('Heap size Limit: ' + Limits.getLimitHeapSize());
    System.debug('Final heap size: ' + Limits.getHeapSize());
    System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
*/
  }
}
