public class SelectedOfferCreateUtil {
    
    public static Plan__c getPlanFromInput(List<String> input) {
        String inputStr = input.get(0);
        List<String> Ids = inputStr.split('\\|');
        String planId = Ids.get(0);
        
        Plan__c selectedPlan = [Select Id, Coverage_Level__c, Coverage_Period__c, Plan_Type__r.Name from Plan__c where Id = :planId];
        return selectedPlan;
    }
    
    public static String getSelectedCoverageTypeFromInput(List<String> input) {
        String inputStr = input.get(0);
        List<String> Ids = inputStr.split('\\|');
        return Ids.get(2);
    }
    
    public static Boolean getWaivedIndicatorFromInput(List<String> input) {
        String inputStr = input.get(0);
        List<String> Ids = inputStr.split('\\|');
        return Boolean.valueOf(Ids.get(3));
    }
    
    public static List<Benefit_Individual__c> getCoveredIndividualsFromInput(List<String> input) {
        String inputStr = input.get(0);
        List<String> Ids = inputStr.split('\\|');
        String individualIdStr = Ids.get(1);
        List<String> individualIds = individualIdStr.split(';');
        
        List<String> coveredIndividualIds = new List<String>();
        
        for(Integer idIndex = 0; idIndex < individualIds.size(); idIndex++) {
            coveredIndividualIds.add(individualIds.get(idIndex));
        }
        
        List<Benefit_Individual__c> coveredIndividuals = [Select Id, Relation__c from Benefit_Individual__c where Id in :coveredIndividualIds];
        
        return coveredIndividuals;
        
    }
    
    public static List<Boolean> getSelectedRelations(List<Benefit_Individual__c> coveredIndividuals) {
        List<Boolean> selectedRelations = new List<Boolean>();
        Boolean isSpouseSelected = false;
        Boolean isChildSelected = false;
        Boolean isSelfSelected = false;
        
        for(Benefit_Individual__c coveredIndividual: coveredIndividuals) {
            if(coveredIndividual.Relation__c == 'Self') {
                isSelfSelected = true;
            }
            else if(coveredIndividual.Relation__c == 'Spouse') {
                isSpouseSelected = true;
            }
            else {
                isChildSelected = true;
            }
        }
        selectedRelations.add(isSelfSelected);
        selectedRelations.add(isSpouseSelected);
        selectedRelations.add(isChildSelected);
        
        return selectedRelations;
    }

}