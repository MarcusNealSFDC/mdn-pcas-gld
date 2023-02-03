@isTest
private class PNNL_PreventBudgetCodeEditTest {
    @TestSetup
    static void loadData() {
        //  Create Budget Reporting Code entry
        Budget_Reporting_Code__c brc = new Budget_Reporting_Code__c();
        brc.Name = '123456';
        brc.Number_of_B_R_Entries__c = 1;
        insert brc;
    }
    @isTest
    static void testBRCUpdate(){
        try{ 
            Budget_Reporting_Code__c brc = [select id, name from Budget_Reporting_Code__c limit 1];
            brc.Name = '987654';
            update brc;            
        }Catch (DMLException e){
            System.assert(e.getMessage().contains('The budget reporting number cannot be changed'), 'The budget reporting number cannot be changed');
        }
    }
    
}