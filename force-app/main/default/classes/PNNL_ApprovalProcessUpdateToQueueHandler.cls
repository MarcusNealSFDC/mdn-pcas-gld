public with sharing class PNNL_ApprovalProcessUpdateToQueueHandler {
    public PNNL_ApprovalProcessUpdateToQueueHandler() {

    }

    @InvocableMethod
    public static void UpdateApprovalProcessesForObject(List<Id> tmpObjectIDs) {
        List<Approval_Process_Node_To_Queue_Mapping__mdt> queueMappings = [
                SELECT 
                    Label, 
                    DeveloperName, 
                    Approval_Process_Node__c, 
                    Replacement_Queue__c 
                FROM Approval_Process_Node_To_Queue_Mapping__mdt
            ] ;

        System.Debug('***queueMappings: ' + queueMappings) ;

        List<ProcessInstance> processInstanceList = [
                SELECT 
                    ID, 
                    CompletedDate, 
                    ElapsedTimeInDays, 
                    ElapsedTimeInHours,
                    ElapsedTimeInMinutes, 
                    LastActorId, 
                    Status, 
                    ProcessDefinition.Name, 
                    TargetObjectId 
                FROM ProcessInstance 
                WHERE TargetObjectId = :tmpObjectIDs
            ] ;
        System.Debug('***processInstanceList: ' + processInstanceList) ;
    }
}
