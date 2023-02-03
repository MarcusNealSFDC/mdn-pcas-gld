@isTest
private class PNNL_PreventBudgetCodeDeletionTest {
    @TestSetup
    static void loadData() {
        //  Create Budget Reporting Code entry
        Budget_Reporting_Code__c brc = new Budget_Reporting_Code__c();
        brc.Name = '123456';
        brc.Number_of_B_R_Entries__c = 1;
        insert brc;
    }
    @isTest
    static void testBRCDelete(){
        try{ 
            Budget_Reporting_Code__c brc = [select id from Budget_Reporting_Code__c limit 1];
            delete brc;            
        }Catch (DMLException e){
            System.assert(e.getMessage().contains('This record cannot be deleted'), 'This record cannot be deleted');
        }
    }
    
}