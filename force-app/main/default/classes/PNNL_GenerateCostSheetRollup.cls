public class PNNL_GenerateCostSheetRollup {
    
    @InvocableMethod
    public static void GenerateCostSheetRollup(List<List<Id>> optyIds){
        // convert opty id list of list to a set
        Set<Id> ids = new Set<Id>();
        for (List<Id> opptylist: optyIds){
            for (Id opId : opptylist){
                ids.add(opId);
            }
        }
        
        Cost_Sheet_Rollup__c[] rollupsToDelete = [select Id from Cost_Sheet_Rollup__c 
        										  where OpportunityId__c in: ids];
        
        // delete all items with ids in the set
        // 
        System.debug('Ids to delete: ');
        System.debug('Number of records: '+ rollupsToDelete.size());
        System.debug(ids);
        
        try {
            delete rollupsToDelete;
        } catch (DmlException e) {
            System.debug(e);
        }

            
        List<AggregateResult> csru = 
            [select OpportunityId, 
             Cost_Sheet_Number__c, 
             Revision_Number__c, 
             PNNL_Project_Account_No__c 
             from OpportunityLineItem where OpportunityId IN: ids
             Group By OpportunityId, Cost_Sheet_Number__c, 
             Revision_Number__c, PNNL_Project_Account_No__c];
        
        System.debug('AggregateResult: ');
        System.debug(csru);
        
        if (csru.size() > 0) {
            List<Cost_Sheet_Rollup__c> csruList = new List<Cost_Sheet_Rollup__c>();
            for (AggregateResult aresult: csru){
                Cost_Sheet_Rollup__c newCSRU = new Cost_Sheet_Rollup__c();
                newCSRU.Cost_Sheet_Number__c = (String) aresult.get('Cost_Sheet_Number__c'); 
                newCSRU.OpportunityId__c = (Id) aresult.get('OpportunityId');
                newCSRU.Revision_Number__c = (String) aresult.get('Revision_Number__c');
                newCSRU.Account__c = (String) aresult.get('PNNL_Project_Account_No__c');
                csruList.add(newCSRU);
            }
            System.debug('Cost Sheet Roll up Record : ');
            System.debug(csruList);
            insert csruList;
        }
        else{
            return;
        }
    }
}