@isTest
public class UploadAttachmentControllerTest {
    
    @testSetup
    static void setup(){
        Account acc = new Account(name='test');
        insert acc;
        Opportunity opp = new Opportunity(Name='test',StageName='Scope Cleared',CloseDate = Date.today(), Contract_Client__c=acc.Id, Funding_Client__c=acc.Id,accountId=acc.Id);
        insert opp;
        Opportunity_Attachment__c OppA = new Opportunity_Attachment__c(Funding_Type__c='FIN Plan Proposal',Attachment_Type__c='Other',Opportunity__c=opp.Id);
        insert OppA;
    }
 
    static testmethod void testCase1(){
		List<Opportunity> Opps = [SELECT Name,StageName,CloseDate,Contract_Client__c,Funding_Client__c,accountId 
                           FROM Opportunity 
                           WHERE Name=:'test' LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opps[0]);
        UploadAttachmentController controller = new UploadAttachmentController(sc);
        
        
        test.startTest();
          controller.processUpload();
          controller.saveStandardAttachment(opps[0].id);
        test.stopTest();
    }    
    static testmethod void testCase2(){
		List<Opportunity> Opps = [SELECT Name,StageName,CloseDate,Contract_Client__c,Funding_Client__c,accountId 
                           FROM Opportunity 
                           WHERE Name=:'test' LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opps[0]);
        UploadAttachmentController controller = new UploadAttachmentController(sc);
        controller.testExceptionValidation = true;
        
        test.startTest();
          controller.processUpload();
          //controller.saveStandardAttachment(opps[0].id);
        test.stopTest();
    }    
}