trigger PNNL_PreventBudgetReportingCodeDeletion on Budget_Reporting_Code__c (before delete) {
    for (Budget_Reporting_Code__c brc : Trigger.old ){
        if (brc.Number_Of_Opportunities__c >0 || brc.Number_of_B_R_Entries__c>0 || brc.Number_of_PNNL_Contracts__c>0){
            brc.addError('This record cannot be deleted because it contains relationships with Proposals, Contracts or Budget and Reporting Entries.'); 
        }
    }
}