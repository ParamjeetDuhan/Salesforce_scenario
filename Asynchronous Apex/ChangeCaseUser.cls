public class ReassignCasesQueueable implements Queueable {

    private List<Id> userIds;

    public ReassignCasesQueueable(List<Id> userIds) {
        this.userIds = userIds;
    }

    public void execute(QueueableContext qc) {
        Id queueId = [
            SELECT Id FROM Group
            WHERE Type = 'Queue' AND DeveloperName = 'My_Queue_Case_Developer'
            LIMIT 1
        ].Id;

        List<Case> openCases = [
            SELECT Id, OwnerId FROM Case
            WHERE OwnerId IN :userIds AND IsClosed = false
        ];

        // ONE map, declared outside the loop, seeded with 0 for every user
        Map<Id, Integer> countPerUser = new Map<Id, Integer>();
        for (Id uid : userIds) {
            countPerUser.put(uid, 0);
        }

        List<Case> toUpdate = new List<Case>();
        for (Case c : openCases) {
            countPerUser.put(c.OwnerId, countPerUser.get(c.OwnerId) + 1);
            toUpdate.add(new Case(Id = c.Id, OwnerId = queueId));
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        // Chain: new transaction, so the callout runs with no pending DML
        System.enqueueJob(new NotifyHrQueueable(countPerUser));
    }
}
