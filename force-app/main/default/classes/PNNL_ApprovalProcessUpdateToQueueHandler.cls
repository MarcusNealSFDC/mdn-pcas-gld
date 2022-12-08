public with sharing class PNNL_ApprovalProcessUpdateToQueueHandler {
    public PNNL_ApprovalProcessUpdateToQueueHandler() {

    }

    @InvocableMethod
    public static void UpdateApprovalProcessesForObject(List<Id> tmpObjectIDs) {
        UpdateApprovalProcessesForObject_future(tmpObjectIDs) ;
    }

    @future
    public static void UpdateApprovalProcessesForObject_future(List<Id> tmpObjectIDs) {
            List<Approval_Process_Node_To_Queue_Mapping__mdt> queueMappings = [
                SELECT 
                    Label, 
                    DeveloperName, 
                    Approval_Process_Node__c, 
                    Replacement_Queue__c 
                FROM Approval_Process_Node_To_Queue_Mapping__mdt
            ] ;
        if(queueMappings.isEmpty()) return ;
        System.Debug('***queueMappings: ' + queueMappings) ;

        Map<Id,Id> nodeId2QueueIDMap = new Map<Id, Id>() ;
        for(Approval_Process_Node_To_Queue_Mapping__mdt tmpMapping: queueMappings) {
            nodeId2QueueIDMap.put(tmpMapping.Approval_Process_Node__c, tmpMapping.Replacement_Queue__c) ;
        }

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
                    AND Status = 'Pending'
            ] ;
        if(processInstanceList.isEmpty()) return ;
        System.Debug('***processInstanceList: ' + processInstanceList) ;

        Id processInstanceID = processInstanceList[0].Id ;
        Set<Id> idSet = nodeId2QueueIDMap.keySet() ;

        List<ProcessInstanceNode> processInstanceNodeList = [
                SELECT 
                    Id, 
                    CompletedDate, 
                    ElapsedTimeInDays, 
                    ElapsedTimeInHours, 
                    ElapsedTimeInMinutes, 
                    LastActorId, 
                    NodeStatus, 
                    ProcessInstanceId, 
                    ProcessNodeId, 
                    ProcessNodeName 
                FROM ProcessInstanceNode
                WHERE ProcessInstanceId = :processInstanceID
                    AND NodeStatus = 'Pending'
                    AND ProcessNodeId IN :idSet
            ] ;
        if(processInstanceNodeList.isEmpty()) return ;
        System.Debug('***processInstanceNodeList: ' + processInstanceNodeList) ;

        ProcessInstanceNode tmpNode = processInstanceNodeList[0] ;
        ID tmpQueueId ;

        if(!nodeId2QueueIDMap.containsKey(tmpNode.ProcessNodeId)) {
            return ;
        } else {
            tmpQueueId = nodeId2QueueIDMap.get(tmpNode.ProcessNodeId) ;
        }

        List<ProcessInstanceWorkItem> processInstanceWorkItemList = [
                SELECT 
                    Id, 
                    ActorId, 
                    Actor.Name, 
                    ElapsedTimeInDays, 
                    ElapsedTimeInHours, 
                    ElapsedTimeInMinutes, 
                    OriginalActorId, 
                    OriginalActor.Name, 
                    ProcessInstanceId
                FROM ProcessInstanceWorkItem 
                WHERE ProcessInstanceId = :processInstanceID
            ] ;
        if(processInstanceWorkItemList.isEmpty()) return ;
        System.Debug('***processInstanceWorkItemList: ' + processInstanceWorkItemList) ;

        processInstanceWorkItemList[0].ActorId = tmpQueueId ;
        update processInstanceWorkItemList ;
    }
}
