public class CaseTriggerHandler {

    public static void autoEscalate(List<Case> newCases, Map<Id, Case> oldMap) {

        for (Case c : newCases) {
            Case old = oldMap.get(c.Id);

            Boolean movedToHigh = (c.Priority == 'High' && old.Priority != 'High');
            Boolean olderThan3Days = (c.CreatedDate <= System.now().addDays(-3));

            if (movedToHigh && olderThan3Days && !c.IsClosed) {
                c.IsEscalated = true;
                c.Description = (c.Description != null ? c.Description + '\n' : '')
                                 + 'Auto-escalated on ' + String.valueOf(System.today());
            }
        }
    }

    public static void preventPriorityDowngrade(List<Case> newCases, Map<Id, Case> oldMap) {

        for (Case c : newCases) {
            Case old = oldMap.get(c.Id);

            if (c.IsEscalated == true && c.Priority == 'Low' && old.Priority != 'Low') {
                c.addError('Escalated Case Priority cannot be set to Low.');
            }
        }
    }
}