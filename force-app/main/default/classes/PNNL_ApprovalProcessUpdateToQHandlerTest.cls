@isTest
public class PNNL_ApprovalProcessUpdateToQHandlerTest {
    // Setup up data for rest of test class.
    @TestSetup
    static void loadData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='PNNL Internal']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.pnnl.pcas');
        insert u ;

        System.runAs(u) {
            //  Create Account
            Id accountId = createAccount();
            
            //  Create Opportunity to Add Opp Line Items
            Id opportunityId = createOpportunity(accountId);   
        }
    }

    private static Id createAccount() {
        Account accountRec = new Account();
        accountRec.Name =
          'Account Test Class Record ' + String.valueOf(getRandomNum(9999));
        insert accountRec;
    
        return accountRec.Id;
    }

    private static Id createOpportunity(Id accountId) {
        final String OPP_REC_NAME =
            'Test Record Name - ' + String.valueOf(getRandomNum(9999));
        final String OPP_REC_TYPE_ACT_NAME = 'DOE Direct';
        final String OPP_STAGE_NAME = 'Proposal Draft';
        final Date closeDate = Date.today() + 30;

        Opportunity oppRec = new Opportunity();
        oppRec.Name = OPP_REC_NAME;
        oppRec.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
            .get(OPP_REC_TYPE_ACT_NAME)
            .getRecordTypeId();
        oppRec.StageName = OPP_STAGE_NAME;
        oppRec.CloseDate = closeDate;
        oppRec.Contract_Client__c = accountId;
        oppRec.Funding_Client__c = accountId;
        oppRec.Pricebook2Id = Test.getStandardPricebookId();
        oppRec.FWP__c = 'Yes' ;
        insert oppRec;

        return oppRec.Id;
    }

    private static Integer getRandomNum(Integer maxNum) {
        Integer retRandom = Integer.valueof((Math.random() * maxNum));
        return retRandom;
    }

    @isTest
    public static void initialSubmission() {
        Opportunity opp = [
            SELECT 
                Id, 
                Name 
            FROM Opportunity 
            LIMIT 1
        ];

        User u = [
            SELECT 
                Alias,
                Email, 
                UserName
            FROM User
            WHERE UserName = 'standarduser@testorg.com.pnnl.pcas' 
            LIMIT 1
        ] ;

        System.debug('***initialSubmission') ;
        System.debug('***initialSubmission: before runAs ' + u) ;
        System.runAs(u) {
            System.debug('***initialSubmission: after runAs ' + u) ;
            // Create an approval request for the account
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(opp.Id);
            
            // Submit on behalf of a specific submitter
            req1.setSubmitterId(u.Id); 
            
            // Submit the record to specific process and skip the criteria evaluation
            req1.setProcessDefinitionNameOrId('FWP_Approval_Non_Office_of_Science2');
            req1.setSkipEntryCriteria(true);
            req1.setNextApproverIds(new Id[] {u.Id }) ;
            
            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);
        }
    }
}