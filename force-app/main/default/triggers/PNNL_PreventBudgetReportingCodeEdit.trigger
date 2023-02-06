trigger PNNL_PreventBudgetReportingCodeEdit on Budget_Reporting_Code__c (before update) {
    for (Budget_Reporting_Code__c brc : Trigger.New ){    
		Budget_Reporting_Code__c oldBrc = Trigger.oldMap.get(brc.ID);
        if (oldBrc.Name != brc.Name){
	        if (brc.Number_Of_Opportunities__c >0 || brc.Number_of_B_R_Entries__c>0 || brc.Number_of_PNNL_Contracts__c>0){
    	        brc.addError('The budget reporting number cannot be changed because it contains relationships with Proposals, Contracts or Budget and Reporting Entries.'); 
        	}
        }
    }
}