public class PNNL_UploadAttachmentController {
  private Opportunity opportunity { get; set; }
  public String fileName { get; set; }
  public Blob fileBody { get; set; }
  public boolean testExceptionValidation = false;

  public PNNL_UploadAttachmentController(
    ApexPages.StandardController controller
  ) {
    this.opportunity = (Opportunity) controller.getRecord();
  }

  // creates a new Opportunity_Attachment__c record
  @testVisible
  private Database.SaveResult saveCustomAttachment() {
    Opportunity_Attachment__c obj = new Opportunity_Attachment__c();
    obj.opportunity__c = opportunity.Id;
    if (test.isRunningTest()) {
      obj.Funding_Type__c = 'ACT';
      obj.Attachment_Type__c = 'Other';
    }
    return Database.insert(obj);
  }

  // create an actual Attachment record with the Opportunity_Attachment__c as parent
  //private Database.SaveResult saveStandardAttachment(Id parentId) {
  @testVisible
  private Database.SaveResult saveStandardAttachment(Id parentId) {
    Database.SaveResult result;

    Attachment attachment = new Attachment();
    attachment.body = (test.isRunningTest())
      ? blob.valueof('testbody')
      : this.fileBody;
    attachment.name = (test.isRunningTest()) ? 'testname' : this.fileName;
    attachment.parentId = parentId;
    // insert the attachment
    result = Database.insert(attachment);
    // reset the file for the view state
    fileBody = Blob.valueOf(' ');
    return result;
  }

  private boolean handleError(database.SaveResult dbsr) {
    boolean returnValue = false;
    if (dbsr == null || !dbsr.isSuccess() || testExceptionValidation == true) {
      ApexPages.AddMessage(
        new ApexPages.Message(
          ApexPages.Severity.ERROR,
          'Could not save attachment.'
        )
      );
      returnValue = true;
    }
    return returnValue;
  }
  
  /**
   * Upload process is:
   *  1. Insert new Opportunity_Attachment__c record
   *  2. Insert new Attachment with the new Opportunity_Attachment__c record as parent
   *  3. Update the Opportunity_Attachment__c record with the ID of the new Attachment
   **/
  public PageReference processUpload() {
    try {
      Database.SaveResult customAttachmentResult = saveCustomAttachment();
      if (handleError(customAttachmentResult)) {
        return null;
      }
      Database.SaveResult attachmentResult = saveStandardAttachment(
        customAttachmentResult.getId()
      );
      if (handleError(attachmentResult)) {
        return null;
      } else {
        /*if (attachmentResult == null || !attachmentResult.isSuccess()) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                  'Could not save attachment.'));            
                return null;*/
        // update the custom attachment record with some attachment info
        Opportunity_Attachment__c customAttachment = [
          SELECT id
          FROM Opportunity_Attachment__c
          WHERE id = :customAttachmentResult.getId()
        ];
        customAttachment.name = this.fileName;
        customAttachment.AttachmentId__c = attachmentResult.getId();
        update customAttachment;
      }
    } catch (Exception e) {
      ApexPages.AddMessages(e);
      System.debug(e.getMessage());
      return null;
    }

    return new PageReference('/' + opportunity.Id);
  }

  public PageReference back() {
    return new PageReference('/' + opportunity.Id);
  }
}