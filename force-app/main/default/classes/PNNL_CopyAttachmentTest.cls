@isTest
private class PNNL_CopyAttachmentTest {
  static Map<Id, Opportunity> insertedOpportunities;
  static Map<Id, Opportunity_Attachment__c> attachments;
  static Map<Id, ContentVersion> contentVersions;

  @TestSetup
  static void loadData() {
    //  Create Account
    Id accountId = createAccount();

    //  Create Opportunity to Add Opp Line Items
    Id opportunityId = createOpportunity(accountId);
    system.debug(opportunityId);
    Id duplicateOpportunityId = createOpportunity(accountId);
    system.debug(duplicateOpportunityId);
    //  Create Opportunity Attachment
    Id attachmentId = createOpportunityAttachment(opportunityId);

    // Create ContentVersion Record
    Id contentVersion = createContentVersion();

    // Create Document Link Record
    Id docLinkRecord = createDocumentLink(attachmentId, contentVersion);
  }

  public static Id createAccount() {
    Account accountRec = new Account();
    accountRec.Name = 'Account Test Class Record ';
    insert accountRec;
    return accountRec.Id;
  }

  public static Id createOpportunity(Id accountId) {
    final String OPP_REC_NAME =
      'Test Record Name - ' + String.valueOf(getRandomNum(9999));
    final String OPP_REC_TYPE_ACT_NAME = 'ACT';
    final String OPP_STAGE_NAME = 'Scope Filled';
    final Date CloseDate = Date.today() + 30;

    Opportunity oppRec = new Opportunity();
    oppRec.Name = OPP_REC_NAME;
    oppRec.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
      .get(OPP_REC_TYPE_ACT_NAME)
      .getRecordTypeId();
    oppRec.StageName = OPP_STAGE_NAME;
    oppRec.CloseDate = CloseDate;
    oppRec.Contract_Client__c = accountId;
    oppRec.Funding_Client__c = accountId;
    insert oppRec;

    return oppRec.Id;
  }

  public static Id createOpportunityAttachment(Id opportunityId) {
    Opportunity_Attachment__c oppAttachment = new Opportunity_Attachment__c();
    oppAttachment.Name = 'My New Attachment';
    oppAttachment.Attachment_Type__c = 'ACT Agreement';
    oppAttachment.Funding_Type__c = 'ACT';
    oppAttachment.Opportunity__c = opportunityId;
    insert oppAttachment;
    return oppAttachment.Id;
  }

  public static Id createContentVersion() {
    ContentVersion cvItem = new ContentVersion();
    cvItem.Title = 'ContentTest';
    cvItem.PathOnClient = 'TestforDocuementClone';
    cvItem.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body');
    insert cvItem;
    return cvItem.Id;
  }

  public static Id createDocumentLink(Id oppAttachment, Id cvItem) {
    ContentVersion versionNewQueried = [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cvItem
      LIMIT 1
    ];
    ContentDocumentLink docLinkNew = new ContentDocumentLink(
      LinkedEntityId = oppAttachment,
      ContentDocumentId = versionNewQueried.ContentDocumentId
    );
    Opportunity_Attachment__c opAttach = new Opportunity_Attachment__c(
      Id = oppAttachment,
      AttachmentId__c = versionNewQueried.ContentDocumentId
    );
    update opAttach;
    insert docLinkNew;
    return docLinkNew.Id;
  }

  private static Integer getRandomNum(Integer maxNum) {
    Integer retRandom = Integer.valueof((Math.random() * maxNum));
    return retRandom;
  }

  static void getIds() {
    insertedOpportunities = new Map<Id, Opportunity>(
      [SELECT Id, Name FROM Opportunity]
    );
    attachments = new Map<Id, Opportunity_Attachment__c>(
      [SELECT Id, Name FROM Opportunity_Attachment__c]
    );
    contentVersions = new Map<Id, ContentVersion>(
      [SELECT Id, Title FROM ContentVersion]
    );

    for (Opportunity opp : insertedOpportunities.values()) {
      System.debug(
        'Opportunity Id :' +
        opp.Id +
        ' ' +
        'Opportunity Name : ' +
        opp.Name
      );
    }
  }
  //after calling the invocable method CopyAttachment, the new opportunity id should have a
  //the same number of attachments and links as the original
  //
  //
  @isTest
  static void testAttachmentCopy() {
    system.debug([SELECT id FROM opportunity].size());
    List<List<Id>> listOfIds = new List<List<Id>>();
    List<Id> listToAdd = new List<Id>();
    getIds();
    for (Opportunity opp : insertedOpportunities.values()) {
      System.debug(
        'Opportunity Id :' +
        opp.Id +
        ' ' +
        'Opportunity Name : ' +
        opp.Name
      );
      listToAdd.add(opp.Id);
    }

    listOfIds.add(listToAdd);

    PNNL_CopyAttachment.CopyAttachment(listOfIds);
    getIds();

    System.assertEquals(2, insertedOpportunities.Size());

    System.assertEquals(2, attachments.Size());

    System.assertEquals(2, contentVersions.size());

    // check the links
    List<Id> checkLinkItems = new List<Id>();
    for (Opportunity_Attachment__c attachment : attachments.values()) {
      List<ContentDocumentLink> docLinkItems = [
        SELECT Id, LinkedEntityId, ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :attachment.Id
      ];
      checkLinkItems.add(docLinkItems[0].Id);
    }

    System.assertEquals(2, checkLinkItems.size());
  }
}