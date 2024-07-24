@IsTest 
public class SelectedOfferCreateUtilTest {

    @testSetup
    public static void setupData() {
        Coverage_Period__c covPeriod = new Coverage_Period__c(Name='Cov Period 2024', Coverage_End_Date__c = Date.newInstance(2024, 12, 31), 
                                                             Coverage_Start_Date__c = Date.newInstance(2024, 1, 1), Open_Enrollment_Start_Date__c = Date.newInstance(2023, 11, 1),
                                                             Open_Enrollment_End_Date__c = Date.newInstance(2023, 12, 31));
        insert covPeriod;
        
        Coverage_Type__c covType = new Coverage_Type__c(Name = 'Dental');
        insert covType;
        
        Plan__c plan = new Plan__c(Name='Aetna Dental', Coverage_Period__c = covPeriod.Id, Monthly_Employee_Cost__c = 100, Coverage_Level__c = 'Employee + Family', Plan_Type__c = covType.Id);
        insert plan;
        
        List<Benefit_Individual__c> coveredIndividuals = new List<Benefit_Individual__c>();
        Benefit_Individual__c self = new Benefit_Individual__c(First_Name__c = 'John', Last_name__c = 'Doe', Date_of_Birth__c = Date.newInstance(1985, 07, 05), 
                                                              National_Identifier__c = '000000000', Relation__c = 'Self');
        
        insert self;
        
        Benefit_Individual__c spouse = new Benefit_Individual__c(First_Name__c = 'Alexa', Last_name__c = 'Doe', Date_of_Birth__c = Date.newInstance(1985, 07, 05), 
                                                              National_Identifier__c = '000000000', Relation__c = 'Spouse', Primary_Coverage_Holder__c = self.Id);
        
        Benefit_Individual__c child = new Benefit_Individual__c(First_Name__c = 'John1', Last_name__c = 'Doe', Date_of_Birth__c = Date.newInstance(2023, 07, 05), 
                                                              National_Identifier__c = '000000000', Relation__c = 'Child', Primary_Coverage_Holder__c = self.Id);
        coveredIndividuals.add(spouse);
        coveredIndividuals.add(child);
        insert coveredIndividuals;
    }
    
    @IsTest
    public static void testCreateSelectedOffer() {
        Plan__c selectedPlan = [Select Id, Coverage_Level__c, Coverage_Period__c, Plan_Type__r.Name from Plan__c where Name = 'Aetna Dental'];
        List<Benefit_Individual__c> coveredIndividuals = [Select Id, Relation__c from Benefit_Individual__c where First_Name__c in ('John', 'Alexa', 'John1')];
        
        List<String> inputs = new List<String>();
        String inputStr = selectedPlan.Id + '|';
        
        for(Benefit_Individual__c individual: coveredIndividuals) {
            inputStr = inputStr + ';' + individual.Id;
        }
        
        inputStr = inputStr + '|Dental|False';
        inputs.add(inputStr);
        
        SelectedOfferCreateAction.createSelectedOffer(inputs);
        
        List<Selected_Offer__c> offersFromDb = [Select Id from Selected_Offer__c];
        
        Assert.isTrue(offersFromDb.size() == 3);
        
    }
    
    @IsTest
    public static void testGetPlanFromInput() {
        Plan__c selectedPlan = [Select Id, Coverage_Level__c, Coverage_Period__c, Plan_Type__r.Name from Plan__c where Name = 'Aetna Dental'];
        String inputStr = selectedPlan.Id;
        List<String> inputs = new List<String>();
        inputs.add(inputStr);
        
        Plan__c planFromFunc = SelectedOfferCreateUtil.getPlanFromInput(inputs);
        
        System.assertEquals(planFromFunc.Id, selectedPlan.Id);
    }
    
    @IsTest
    public static void testGetSelectedCoverageTypeFromInput() {
        String inputStr = '||Dental';
        List<String> inputs = new List<String>();
        inputs.add(inputStr);
        
        System.assertEquals(SelectedOfferCreateUtil.getSelectedCoverageTypeFromInput(inputs), 'Dental');
    }
    
    @IsTest
    public static void testGetWaivedIndicatorFromInput() {
        String inputStr = '||Dental|True';
        List<String> inputs = new List<String>();
        inputs.add(inputStr);
        
        System.assertEquals(SelectedOfferCreateUtil.getWaivedIndicatorFromInput(inputs), True);
    }
    
    @IsTest
    public static void testGetCoveredIndividualsFromInput() {
        List<Benefit_Individual__c> coveredIndividuals = [Select Id, Relation__c from Benefit_Individual__c where First_Name__c in ('John', 'Alexa', 'John1')];
        String inputStr = '|';
        for(Benefit_Individual__c individual: coveredIndividuals) {
            inputStr = inputStr + ';' + individual.Id;
        }
        inputStr = inputStr + '|Dental|True|';
        
        List<String> inputs = new List<String>();
        inputs.add(inputStr);
        
        List<Benefit_Individual__c> coveredIndividualsFromFunction = SelectedOfferCreateUtil.getCoveredIndividualsFromInput(inputs);
        System.assertEquals(coveredIndividuals, coveredIndividualsFromFunction);
    }
    
    @IsTest
    public static void testGetSelectedRelations() {
        List<Benefit_Individual__c> coveredIndividuals = [Select Id, Relation__c from Benefit_Individual__c where First_Name__c in ('John', 'Alexa', 'John1')];
        
        List<Boolean> selectedRelations = SelectedOfferCreateUtil.getSelectedRelations(coveredIndividuals);
 
        Assert.isTrue(selectedRelations.get(0) && selectedRelations.get(1) && selectedRelations.get(2));
        
    }
}