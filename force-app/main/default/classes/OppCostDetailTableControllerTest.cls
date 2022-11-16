@isTest public class OppCostDetailTableControllerTest {
    final static Integer ZERO_ITEMS = 0;

    @TestSetup
    static void loadData(){
        //  Create Product Records
        createProductRecords();

        //  Create Account
        Id accountId = createAccount();

        //  Create Opportunity to Add Opp Line Items
        Id opportunityId = createOpportunity(accountId);

        //  Create Opportunity 2, to *Not* Add Opp Line Items
        createOpportunity(accountId);

        //  Create Opportunity Line Items
        createOpportunityLineItems(opportunityId);
    }

    private static void createProductRecords() {
        Id pricebook2Id = Test.getStandardPricebookId();

        List<String> productCodeList = new List<String>{'Materials','Subcontract','Other'};
        
        List<Product2> productList = new List<Product2>();
        
        for(String productCode : productCodeList) {
            productList.add(new Product2(Name=productCode, ProductCode=productCode));
        }
        insert productList;
        
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for(Product2 product : productList) {
            pricebookEntries.add(new PricebookEntry(Product2Id=product.Id, Pricebook2Id=pricebook2Id, UnitPrice=0, IsActive=true));
        }
        insert pricebookEntries;
    }

    private static Id createAccount() {
        Account accountRec = new Account();
        accountRec.Name = 'Account Test Class Record ' + String.valueOf(getRandomNum(9999));
        insert accountRec;

        return accountRec.Id;
    }

    private static Id createOpportunity(Id accountId) {
        final String OPP_REC_NAME = 'Test Record Name - ' + String.valueOf(getRandomNum(9999));
        final String OPP_REC_TYPE_SPP_NAME = 'F-SPP';
        final String OPP_STAGE_NAME = 'Proposal Submitted';
        final Date CloseDate = Date.today() + 30;

        Opportunity oppRec = new Opportunity();
        oppRec.Name = OPP_REC_NAME;
        oppRec.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(OPP_REC_TYPE_SPP_NAME).getRecordTypeId();
        oppRec.StageName = OPP_STAGE_NAME;
        oppRec.CloseDate = CloseDate;
        oppRec.Contract_Client__c = accountId;
        oppRec.Funding_Client__c = accountId;
        oppRec.Pricebook2Id = Test.getStandardPricebookId();
        insert oppRec;

        return oppRec.Id;
    }

    private static void createOpportunityLineItems(Id oppId) {
        Integer startYear = 2018;
        Integer reportYearCount = 5;
        Integer maxYear;
        
        Integer currentYear = Date.today().year();
        maxYear = currentYear + reportYearCount;

        List<OpportunityLineItem> lineItemRecs = new List<OpportunityLineItem>();
        Set<String> productCodeSet = new Set<String>{'Materials','Subcontract','Other'};

        List<Product2> productList = new List<Product2>([SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN: productCodeSet]);
    
        //   Loop Years
        Integer maxLines; 
        String productCode;

        for(Integer reportYear=startYear; reportYear < maxYear; reportYear++) {

            maxLines = getRandomNum(11) + 1;
            for(Integer itemIndx=0; itemIndx < maxLines; itemIndx++) {
                lineItemRecs.add(new OpportunityLineItem(OpportunityId=oppId, Fiscal_Year__c=reportYear, Product2Id=getProductId(productList), Quantity=1, TotalPrice=getPrice()));
            }
        }

        if(!lineItemRecs.isEmpty()) {
            insert lineItemRecs;
        }
    }

    private static Id getProductId(List<Product2> productList) {
        Integer index = getRandomNum(3);
        Id product2Id = productList[index].Id;

        return product2Id;
    }

    private static Decimal getPrice() {
        Decimal retPrice;

        retPrice = Decimal.valueOf(getRandomNum(20)) * 100;

        return retPrice;
    }

    private static Integer getRandomNum(Integer maxNum) {
        Integer retRandom = Integer.valueof((Math.random() * maxNum));
        return retRandom;
    }

    @isTest
    public static void whenOppHasLineItemsReturnOppDetailTable() {
        Id oppId;

        List<Opportunity> oppRecs = [SELECT Id, (Select Id FROM OpportunityLineItems) FROM Opportunity];

        for(Opportunity oppRec : oppRecs) {
            if(oppRec.OpportunityLineItems.size() > ZERO_ITEMS) {
                oppId = oppRec.Id;
                break;
            }
        }
        
        OppCostDetailTableController.OppDetailClass oppDetailClass;        
        if(oppId != null) {
            oppDetailClass = OppCostDetailTableController.getOppDetail(oppId);
        }
        System.assert(oppDetailClass != null && oppDetailClass.columns.size() > ZERO_ITEMS);
        System.assert(oppDetailClass != null && oppDetailClass.recs.size() > ZERO_ITEMS);
    }

    @isTest
    public static void whenOppHasNoLineItemsReturnEmptyOppDetailTable() {
        Id oppId;

        List<Opportunity> oppRecs = [SELECT Id, (Select Id FROM OpportunityLineItems) FROM Opportunity];

        system.debug('@@oppRecs.size():'+oppRecs.size());

        for(Opportunity oppRec : oppRecs) {

            system.debug('@@oppRec.OpportunityLineItems.size():'+oppRec.OpportunityLineItems.size());

            if(oppRec.OpportunityLineItems.size() == ZERO_ITEMS) {
                oppId = oppRec.Id;
                break;
            }
        }
        
        OppCostDetailTableController.OppDetailClass oppDetail;        

        system.debug('@@oppId:'+oppId);

        if(oppId != null) {
            oppDetail = OppCostDetailTableController.getOppDetail(oppId);
        }


        system.debug('@@oppDetail:'+oppDetail);
        if(oppDetail != null) {
            system.debug('@@oppDetail.columns:'+oppDetail.columns);
            system.debug('@@oppDetail.recs:'+oppDetail.recs);
        }

        System.assert(oppDetail != null && oppDetail.columns.size() > ZERO_ITEMS);
        System.assert(oppDetail != null && oppDetail.recs.size() == ZERO_ITEMS);
    }

}
