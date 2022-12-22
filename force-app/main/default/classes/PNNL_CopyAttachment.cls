public class PNNL_CopyAttachment {
  final Boolean DONT_PRESERVE_ID = false;
  final Boolean IS_DEEP_CLONE = true;
  final Boolean DONT_PRESERVE_TIMESTAMPS = false;
  final Boolean DONT_PRESERVE_AUTONUMBER = false;

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
    List<Opportunity_Attachment__c> oppAttachItems = [
      SELECT
        Id,
        Name,
        Funding_Type__c,
        Attachment_Type__c,
        RecordTypeId,
        Opportunity__c
      FROM Opportunity_Attachment__c
      WHERE Opportunity__c = :opptyId
    ];
    // loop at attachments
    for (Opportunity_Attachment__c oppAttachItem : oppAttachItems) {
      system.debug(oppAttachItem);

      //	Clone Attachment Record
      Opportunity_Attachment__c oppAttachClone = oppAttachItem.clone(
        false,
        true,
        false,
        false
      );
      oppAttachClone.Name = '(Cloned) ' + oppAttachClone.Name;
      oppAttachClone.Opportunity__c = clonedOppty;
      insert oppAttachClone;

      List<ContentDocumentLink> docLinkItems = [
        SELECT Id, LinkedEntityId, ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :oppAttachItem.Id
      ];
      system.debug('oppAttachClone:' + oppAttachClone.Id);
      system.debug(oppAttachClone);

      //Loop at document link items
      for (ContentDocumentLink docLinkItem : docLinkItems) {
        ContentVersion versionItem = [
          SELECT FIELDS(STANDARD)
          FROM ContentVersion
          WHERE
            ContentDocumentId = :docLinkItem.ContentDocumentId
            AND IsLatest = TRUE
          LIMIT 1
        ];

        system.debug(versionItem);
        System.savepoint sp = Database.setSavepoint();
        //	Clone ContentVersion Record
        ContentVersion versionNew = new ContentVersion(
          VersionData = versionItem.VersionData,
          Title = versionItem.Title,
          ContentUrl = versionItem.ContentUrl,
          PathOnClient = versionItem.PathOnClient
        );
        insert versionNew;

        //	Retrieve ContentDocumentId
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
