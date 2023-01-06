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

    Map<Id, ContentVersion> versionItem = new Map<Id, ContentVersion>(
      [SELECT FIELDS(STANDARD) FROM ContentVersion WHERE IsLatest = TRUE]
    );

    // loop at Map values for attachments
    for (Opportunity_Attachment__c oppAttachItem : oppAttachItems.values()) {
      system.debug(oppAttachItem);

      //	Clone Attachment Record
      Opportunity_Attachment__c oppAttachClone = oppAttachItem.clone(
        false,
        true,
        false,
        false
      );
      oppAttachClone.Name = oppAttachClone.Name;
      oppAttachClone.Opportunity__c = clonedOppty;
      insert oppAttachClone;

      // This select statement in the for loop is unavoidable because the query to the ContentDocumentLink object must include a where clause
      // with either the linkedEntityId or ContentDocumentId - neither of which is available outside of a loop.
      List<ContentDocumentLink> docLinkItems = [
        SELECT Id, LinkedEntityId, ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :oppAttachItem.Id
      ];
      system.debug('oppAttachClone:' + oppAttachClone.Id);
      system.debug(oppAttachClone);

      //Loop at document link items
      for (ContentDocumentLink docLinkItem : docLinkItems) {
        Id versionItemId;
        // need to loop over the map of contentDocuments
        // and find the right one rather than query inside the loop
        for (ContentVersion item : versionItem.values()) {
          if (docLinkItem.ContentDocumentId == item.ContentDocumentId)
            versionItemId = item.Id;
        }

        ContentVersion versionItemfound = versionItem.get(versionItemId);

        System.savepoint sp = Database.setSavepoint();
        //	Clone ContentVersion Record
        ContentVersion versionNew = new ContentVersion(
          VersionData = versionItemfound.VersionData,
          Title = versionItemfound.Title,
          ContentUrl = versionItemfound.ContentUrl,
          PathOnClient = versionItemfound.PathOnClient
        );
        insert versionNew;

        //	Retrieve ContentDocumentId
        //	This query retrieves the newly created ContentDocumentId - also unavoidable.
        ContentVersion versionNewQueried = [
          SELECT ContentDocumentId
          FROM ContentVersion
          WHERE Id = :versionNew.Id
          LIMIT 1
        ];
        system.debug(versionNewQueried.ContentDocumentId);

        //	Create ContentDocument Link
        ContentDocumentLink docLinkNew = new ContentDocumentLink(
          LinkedEntityId = oppAttachClone.Id,
          ContentDocumentId = versionNewQueried.ContentDocumentId
        );
        insert docLinkNew;
      }
    }
  }
}
