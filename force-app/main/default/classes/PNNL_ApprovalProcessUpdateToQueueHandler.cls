public with sharing class PNNL_ApprovalProcessUpdateToQueueHandler {

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
                Approval_Process_Developer_Name__c,
                Approval_Step_Developer_Name__c, 
                Replacement_Queue__c 
            FROM Approval_Process_Node_To_Queue_Mapping__mdt
        ] ;
        if(queueMappings.isEmpty()) return ;
        System.Debug('***queueMappings: ' + queueMappings) ;

        Map<String,String> approvalStepToQueueMap = new Map<String, String>() ;
        Set<String> definitionDeveloperNameSet = new Set<String>() ;
        Set<String> nodeDeveloperNameSet = new Set<String>() ;
        Set<String> queueDeveloperNameSet = new Set<String>() ;
        for(Approval_Process_Node_To_Queue_Mapping__mdt tmpMapping: queueMappings) {
            definitionDeveloperNameSet.add(tmpMapping.Approval_Process_Developer_Name__c) ;
            nodeDeveloperNameSet.add(tmpMapping.Approval_Step_Developer_Name__c) ;
            queueDeveloperNameSet.add(tmpMapping.Replacement_Queue__c) ;
            // Using the concatenated DeveloperNames we can create a unique key that defines the Queue to use
            approvalStepToQueueMap.put(tmpMapping.Approval_Process_Developer_Name__c+tmpMapping.Approval_Step_Developer_Name__c, 
                    tmpMapping.Replacement_Queue__c) ;
        }

        List<Group> groupList = [
            SELECT 
                Name, 
                Type, 
                DeveloperName 
            FROM Group 
                WHERE Type = 'Queue' 
                    AND DeveloperName IN :queueDeveloperNameSet
        ] ;
        if(groupList.isEmpty()) return ;
        System.Debug('***groupList: ' + groupList) ;

        Map<String, Id> mapQueueToId = new Map<String, Id>() ;
        for(Group tmpGroup: groupList) {
            mapQueueToId.put(tmpGroup.DeveloperName, tmpGroup.Id) ;
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
                    ProcessDefinition.DeveloperName, 
                    TargetObjectId 
                FROM ProcessInstance 
                WHERE TargetObjectId = :tmpObjectIDs
                    AND Status = 'Pending'
                    AND ProcessDefinition.DeveloperName IN :definitionDeveloperNameSet
            ] ;
        if(processInstanceList.isEmpty()) return ;
        System.Debug('***processInstanceList: ' + processInstanceList) ;

        Id processInstanceID = processInstanceList[0].Id ;
        String processDefinitionDeveloperName = processInstanceList[0].ProcessDefinition.DeveloperName ;

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
                    ProcessNodeName,
                    ProcessNode.DeveloperName 
                FROM ProcessInstanceNode
                WHERE ProcessInstanceId = :processInstanceID
                    AND NodeStatus = 'Pending'
                    AND ProcessNode.DeveloperName IN :nodeDeveloperNameSet
            ] ;
        if(processInstanceNodeList.isEmpty()) return ;
        System.Debug('***processInstanceNodeList: ' + processInstanceNodeList) ;

        ProcessInstanceNode tmpNode = processInstanceNodeList[0] ;
        String nodeDeveloperName = tmpNode.ProcessNode.DeveloperName ;
        ID tmpQueueId ;

        if(!approvalStepToQueueMap.containsKey(processDefinitionDeveloperName+nodeDeveloperName)) {
            return ;
        } else {
            if(!mapQueueToId.containsKey(approvalStepToQueueMap.get(processDefinitionDeveloperName+nodeDeveloperName))) {
                return ;
            } else {
                tmpQueueId = mapQueueToId.get(approvalStepToQueueMap.get(processDefinitionDeveloperName+nodeDeveloperName)) ;
            }
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
        processInstanceWorkItemList[0].OriginalActorId = tmpQueueId ;
        update processInstanceWorkItemList ;
    }
}
