@isTest
private class PNNL_GenerateCostSheetRollupTest {
    
    static Id standardPBEId;
    
    @TestSetup
    static void loadData(){
        
        // Create Products
        createProducts();
        
        // Create Account
        Id accountId = createAccount();
        
        //  Create Opportunity to Add Opp Line Items
        Id opportunityId = createOpportunity(accountId);
        
        //  Create Opportunity Line Item
        //  
        createOpportunityLineItems(opportunityId);

    }
    
    public static void createProducts(){
        Pricebook2 pricebook2 = new Pricebook2(Name='Standard Price Book');
        insert pricebook2;

        Product2 product2 = new Product2(Name='Misc', isActive=true ,Family = 'Equipment');
        insert product2;

        insert new PriceBookEntry(Product2Id=product2.Id, Pricebook2Id=Test.getStandardPricebookId(), isActive=true,UnitPrice=0);
        PricebookEntry pbe =new PricebookEntry(UnitPrice=10000,Product2Id=product2.Id,Pricebook2Id=pricebook2.id,
                                             isActive=true,UseStandardPrice = false);
        insert pbe;
        standardPBEId = pbe.Id;
    }
    
    public static void createOpportunityLineItems(Id oppId){
        OpportunityLineItem item = new OpportunityLineItem();
        item.OpportunityId = oppId;
        item.Cost_Sheet_Number__c = '5555';
        item.Revision_Number__c = '1';
        item.PNNL_Project_Account_No__c = '1212';
        item.Quantity = 1;
        item.TotalPrice = 5;
        item.PricebookEntryId = standardPBEId;
        insert item;
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
    
    private static Integer getRandomNum(Integer maxNum) {
        Integer retRandom = Integer.valueof((Math.random() * maxNum));
        return retRandom;
    }
    
    @isTest
    static void testGenerateCostSheetRollup(){
        List<Opportunity> oppty = [select Id from Opportunity];
        Id opptyId = oppty[0].Id;
        List<List<Id>> listOfIds = new List<List<Id>>();
        List<Id> listToAdd = new List<Id>();
        //System.debug('OpportunityId: '+ oppty[0].Id);
        listToAdd.add(opptyId);
        listOfIds.add(listToAdd);
        
        PNNL_GenerateCostSheetRollup.GenerateCostSheetRollup(listOfIds);
        System.debug('Opportunity Ids to rollup: ');
        System.debug(listToAdd);
        List<Cost_Sheet_Rollup__c> rollup = [select Id from Cost_Sheet_Rollup__c
                                            where OpportunityId__c in :oppty];
        assert.areEqual(1, rollup.size());
    }
}