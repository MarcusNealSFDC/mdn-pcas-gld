public class PNNL_CopyAttachment {
  public static string clonedOppty;

  public PNNL_CopyAttachment() {
  }

  @InvocableMethod
  public static void CopyAttachment(List<List<Id>> opptyIds) {
    clone_opptyAttachments(opptyIds);
  }

  public static void clone_opptyAttachments(List<List<Id>> opptyIds) {
    string opptyId = opptyIds[0][0];
    string clonedOppty = opptyIds[0][1];
    System.debug(
      'Number of Queries used in this apex code so far: ' + Limits.getQueries()
    );
    Map<Id, Opportunity_Attachment__c> oppAttachItems = new Map<Id, Opportunity_Attachment__c>(
      [
        SELECT
          Id,
          Name,
          Funding_Type__c,
          Attachment_Type__c,
          RecordTypeId,
          Opportunity__c
        FROM Opportunity_Attachment__c
        WHERE Opportunity__c = :opptyId
      ]
    );
    System.debug(
      'Number of Queries used in this apex code so far: ' + Limits.getQueries()
    );
    Map<Id, ContentVersion> versionItem = new Map<Id, ContentVersion>(
      [
        SELECT fields(standard)
        FROM ContentVersion
        WHERE IsLatest = TRUE AND IsDeleted = FALSE
      ]
    );
    System.debug(
      'Number of Queries used in this apex code so far: ' + Limits.getQueries()
    );
    // loop at the attachment list and place clone records in a list
    List<Opportunity_Attachment__c> attchList = new List<Opportunity_Attachment__c>();
    for (Opportunity_Attachment__c oppAttachItem : oppAttachItems.values()) {
      system.debug('The original attachment: ' + oppAttachItem);
      system.debug('The original attachment id: ' + oppAttachItem.Id);

      //	Clone Attachment Record
      Opportunity_Attachment__c oppAttachClone = oppAttachItem.clone(
        false,
        true,
        false,
        false
      );
      oppAttachClone.Name = oppAttachClone.Name;
      oppAttachClone.Opportunity__c = clonedOppty;
      attchList.add(oppAttachClone);
    }
    // insert the list of attachment records
    insert attchList;
    System.debug(
      'Number of Queries used in this apex code so far: ' + Limits.getQueries()
    );
    // Execute select statement once for all opportunity_attachment__c records
    // outside of a loop.
    List<ContentDocumentLink> docLinkItems = [
      SELECT Id, LinkedEntityId, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN :oppAttachItems.keySet()
    ];
    System.debug(
      'Number of Queries used after retreiving the doclinkitems: ' +
      Limits.getQueries()
    );
    //for debugging only
    /*  for (ContentDocumentLink cdl : docLinkItems){
          system.debug('The original doclinkedItems:');
          system.debug(cdl);
      }
      
      for (Opportunity_Attachment__c newCloneAttachment: [select id, name from Opportunity_Attachment__c where id IN :attchList]){
          system.debug('This is the new list of attachments: '+ newCloneAttachment);
      }
      */
    integer oppattachCount = 0;
    integer doclinkCount = 0;
    boolean foundDocument = false;
    ContentDocumentLink[] cdls = new List<ContentDocumentLink>();
    for (Opportunity_Attachment__c newCloneAttachment : [
      SELECT id, name
      FROM Opportunity_Attachment__c
      WHERE id IN :attchList
    ]) {
      //Loop at document link items
      //
      //
      doclinkCount = 0;
      for (ContentDocumentLink docLinkItem : docLinkItems) {
        Id versionItemId;
        Id linkedEntity = docLinkItem.LinkedEntityId;
        // need to find the document version record that matches the original document link record
        // in order to copy it.
        for (ContentVersion item : versionItem.values()) {
          if (docLinkItem.ContentDocumentId == item.ContentDocumentId) {
            foundDocument = true;
            versionItemId = item.Id;
            ContentVersion versionItemfound = versionItem.get(versionItemId);
            ContentVersion versionNew = new ContentVersion(
              VersionData = versionItemfound.VersionData,
              Title = versionItemfound.Title,
              ContentUrl = versionItemfound.ContentUrl,
              PathOnClient = versionItemfound.PathOnClient
            );
            //System.debug('Number of DML statements used so far : ' + Limits.getDmlStatements());
            insert versionNew;
            //System.debug('Number of DML statements used so far : ' + Limits.getDmlStatements());
            system.debug('VersionNew Id value: ' + versionNew.Id);
            system.debug('after the insert for version record.');
            ContentVersion versionNewQueried = [
              SELECT ContentDocumentId
              FROM ContentVersion
              WHERE Id = :versionNew.Id
              LIMIT 1
            ];

            cdls.add(
              new ContentDocumentLink(
                LinkedEntityId = newCloneAttachment.Id,
                ContentDocumentId = versionNewQueried.ContentDocumentId
              )
            );
            break;
          }
          //system.debug('content document id:' + linkedEntity);
          //system.debug('Linked Entity id: '+ docLinkItem.LinkedEntityId);
          if (foundDocument)
            break;
        }
        system.debug('the content document list');
        system.debug(cdls);
      }
    }
    insert cdls;
    System.debug('Limit script statements : ' + Limits.getLimitDmlStatements());
    System.debug(
      'Final number of script statements used so far : ' +
      Limits.getDmlStatements()
    );
    System.debug('Heap size Limit: ' + Limits.getLimitHeapSize());
    System.debug('Final heap size: ' + Limits.getHeapSize());
    System.debug(
      'Total Number of SOQL Queries allowed in this apex code context: ' +
      Limits.getLimitQueries()
    );
    System.debug(
      'Number of Queries used in this apex code so far: ' + Limits.getQueries()
    );
  }
}
