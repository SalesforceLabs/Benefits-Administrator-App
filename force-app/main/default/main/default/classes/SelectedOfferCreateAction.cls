public with sharing class SelectedOfferCreateAction {
    
    @InvocableMethod(label='Create SelectedOffer' description='Creates SelectedOffer from provided inputs')
    public static void createSelectedOffer(List<String> input) {
        
        String selectedCoverageType = SelectedOfferCreateUtil.getSelectedCoverageTypeFromInput(input);
        Boolean waivedIndicator = SelectedOfferCreateUtil.getWaivedIndicatorFromInput(input);
       

        if(!waivedIndicator) {
            Plan__c selectedPlan = SelectedOfferCreateUtil.getPlanFromInput(input);
        	List<Benefit_Individual__c> coveredIndividuals = SelectedOfferCreateUtil.getCoveredIndividualsFromInput(input);
        	List<Boolean> selectedRelations = SelectedOfferCreateUtil.getSelectedRelations(coveredIndividuals);
        	
            validateIfSelfIsSelected(selectedRelations);
        	validateIfCorrectPlanIsSelected(selectedRelations, selectedPlan);
            
            saveSelectedOffers(coveredIndividuals, selectedPlan);
    	}
        
        else {
            removeSelectedCoveragesOfGivenType(selectedCoverageType);
        }
        
    }
    
    // Every plan must have the Salesforce Platform User as a covered individual
    private static void validateIfSelfIsSelected(List<Boolean> selectedRelations) {
        Boolean isSelfSelected = selectedRelations.get(0);
        Boolean isSpouseSelected = selectedRelations.get(1);
        Boolean isChildSelected = selectedRelations.get(2);
        
        if(!isSelfSelected) {
            throw new CalloutException('E001:You must select yourself as a covered individual');
        }
    }
    
    private static void validateIfCorrectPlanIsSelected(List<Boolean> selectedRelations, Plan__c selectedPlan) {
        
        Boolean isSelfSelected = selectedRelations.get(0);
        Boolean isSpouseSelected = selectedRelations.get(1);
        Boolean isChildSelected = selectedRelations.get(2);
        
        if(isChildSelected && selectedPlan.Coverage_Level__c != 'Employee + Family') {
            throw new CalloutException('E002:You must select a plan with coverage level as Employee + Family to cover the Child.');
        }
        
        else if(isSpouseSelected && selectedPlan.Coverage_Level__c == 'Employee') {
            throw new CalloutException('E003:You must select a plan with coverage level as Employee + Spouse to cover the Spouse.');
        }
    }
    
    private static void removeSelectedCoveragesOfGivenType(String selectedCoverageType) {
        List<Selected_Offer__c> existingSelectedOffers = [Select Id, Plan__c, Plan__r.Coverage_Period__c from Selected_Offer__c so 
                                                          where so.Plan_Type__c = :selectedCoverageType];
        
        List<Coverage_Period__c> currentlyOpenCoveragePeriod = [Select Id, Coverage_Start_Date__c, Coverage_End_Date__c from Coverage_Period__c cp where cp.Coverage_Start_Date__c <= TODAY and cp.Coverage_End_Date__c >= TODAY];
        Id selectedCoveragePeriod = currentlyOpenCoveragePeriod.get(0).Id;
        
        List<Selected_Offer__c> offersToDelete = new List<Selected_Offer__c>();
        
        for(Selected_Offer__c existingSelectedOffer: existingSelectedOffers) {
            if(existingSelectedOffer.Plan__r.Coverage_Period__c == selectedCoveragePeriod) {
                offersToDelete.add(existingSelectedOffer);
            }
        }
        
        delete offersToDelete;
    }

    private static void saveSelectedOffers(List<Benefit_Individual__c> coveredIndividuals, Plan__c selectedPlan) {
        List<Selected_Offer__c> selectedOffers = new List<Selected_Offer__c>();
        
        List<Benefit_Individual__c> connectedIndividuals = [Select Id from Benefit_Individual__c where Primary_Coverage_Holder__c in :coveredIndividuals];
        List<Benefit_Individual__c> allIndividuals = new List<Benefit_Individual__c>();
        allIndividuals.addAll(connectedIndividuals);
        allIndividuals.addAll(coveredIndividuals);
        
        String selectedPlanType = selectedPlan.Plan_Type__r.Name;
        
        List<Selected_Offer__c> existingSelectedOffers = [Select Id, Plan__c, Plan__r.Coverage_Period__c from Selected_Offer__c so 
                                                          where so.Covered_Individual__c in :allIndividuals and so.Plan_Type__c = :selectedPlanType];
        
        List<Selected_Offer__c> offersToDelete = new List<Selected_Offer__c>();
        
        Id selectedCoveragePeriod = selectedPlan.Coverage_Period__c;
        
        for(Selected_Offer__c existingSelectedOffer: existingSelectedOffers) {
            if(existingSelectedOffer.Plan__r.Coverage_Period__c == selectedCoveragePeriod) {
                offersToDelete.add(existingSelectedOffer);
            }
        }
        
        delete offersToDelete;
        
        for(Benefit_Individual__c coveredIndividual: coveredIndividuals) {
            Selected_Offer__c selectedOffer = new Selected_Offer__c(Plan__c = selectedPlan.Id, Covered_Individual__c = coveredIndividual.Id);
            selectedOffers.add(selectedOffer);
        }
        insert selectedOffers;
        
    }
}