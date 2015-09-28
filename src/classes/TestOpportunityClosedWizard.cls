@isTest
private class TestOpportunityClosedWizard {

    static testMethod void opportunityWizardTest() { 
        Account acctest12 = new Account();
        acctest12.Name='TestAccount12';
        acctest12.RC_Attribution_Channel__c = 'National Accounts';
        acctest12.Partner_ID__c ='123';
        acctest12.Number_of_DL_s__c = 10;
        acctest12.RecordTypeId  = '01280000000UERq';
        
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest12;
        
        Opportunity Oppval12 = new Opportunity();
        Oppval12.Name = 'Test Opp12';
        Oppval12.AccountId = acctest12.Id;
        Oppval12.Type = 'Existing Business';
        Oppval12.StageName = '3. ActivePipe';
        Oppval12.Sales_Model__c = 'Direct';
        Oppval12.StageName= '7.Closed Won';
        Oppval12.Probability = 100;
        Oppval12.Other_Competitor_Who_did_we_beat__c ='Hosted PBx';
        Oppval12.Who_What_are_we_replacing__c ='test';
        Oppval12.Who_Did_We_Beat__c ='Hosted Pbx';
        Oppval12.CloseDate = System.Today() + 10;
        Oppval12.CurrencyIsoCode = 'USD';
        Oppval12.Brand_Name__c= 'RingCentral';
        Oppval12.Forecasted_Users__c =12;
        Oppval12.Tier_Name__c ='100';
        Oppval12.Why_did_we_win__c='Integrations';
        Oppval12.Competitor_Why_did_We_Win__c = 'Quality of Service / Product';
        Oppval12.Competitor_Who_What_are_we_replacing__c = 'Land Lines';
        Oppval12.Competitor_Other_Cloud__c ='test';
        Oppval12.Competitor_Who_did_we_beat__c ='Land Lines';      
       // Oppval12.Why_did_we_win__c 
        Oppval12.RecordTypeId = '01280000000UEtu';
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        insert Oppval12;
         Test.startTest(); 
        
        ApexPages.currentPage().getParameters().put('id', Oppval12	.id);     
        boolean toshowWonReasonIntegrations ;
        boolean  toshowWonReasonServiceAndFeatures;
        boolean toshowWonReasonAll;
        String  strSelectedWhoDidWeWin = 'Integration' ;
        List<String> testclosOppty = new List<String>();
        testclosOppty.add('Services and Features');
        testclosOppty.add('Integrations');
        testclosOppty.add('Won Reason-All');
        
        set<String> tests = new set<String>();       
        tests.add('Google Integration');
        tests.add('Quality of Service / Product');
        tests.add(' Multi-Level IVR');
        
        String strSectedWonReasonOption = '';
        Set<String> setSelectedWonReasonOption = new Set<String>();
        OpportunityClosedWizard obj = new OpportunityClosedWizard(new ApexPages.StandardController(Oppval12));
        obj.getHostedPBX();
        obj.getHostedPBX1();
        obj.getHostedPBXRCandRCCanada();
        obj.getHostedPBXRCUK();
        obj.getOnPremisePBX();
        obj.getOnPremisePBX1();
        obj.getWhoDidWeBeat();
        obj.getWhoDidWeWin();
        obj.getWhoWhatAreWeReplacing();
        obj.getWonReasonServiceAndFeatures();
        obj.getWonReasonIntegrations();
        obj.getWonReasonAll();
        obj.cancel();
        obj.showtoOtherOnPremisePBX1();
        obj.showtoOtherHostedPBX1();      
        obj.showtoOtheronPremisePBX();
        obj.showtoOtherHostedPBX();
        obj.showSubSectionOfWhoDidWeBeat();
        obj.showSubSectionOfWhoDidWeBeat1();
        obj.strSelectedWhoDidWeBeat = 'On-Premise PBX';
        obj.strSelectedWhoDidWeBeat1 = 'On-Premise PBX';
        obj.showSubSectionOfWhoDidWeWin();
        obj.showSubSectionOfWhoDidWeBeat();
        obj.showSubSectionOfWhoDidWeBeat1(); 
        obj.strSelectedWhoDidWeBeat = 'Hosted PBX';
        obj.strSelectedWhoDidWeBeat1 = 'Hosted PBX';
        obj.toShowImplementationScheduler = true;
        obj.lstSelectedWonReasonIntegrations = testclosOppty; 
        obj.toshowWonReasonIntegrations = true;
        obj.lstSelectedWonReasonAll = testclosOppty;
        obj.toshowWonReasonServiceAndFeatures = true;
        obj.lstSelectedWonReasonIntegrations =testclosOppty;
        obj.showSubSectionOfWhoDidWeBeat();
        obj.showSubSectionOfWhoDidWeBeat1();
        obj.showSubSectionOfWhoDidWeWin();
        obj.OpportunityUpdate();
        obj.strSelectedWhoDidWeBeat = 'Land Lines';
        obj.strSelectedWhoDidWeBeat1 = 'Land Lines';
        obj.OpportunityUpdate();
        obj.strSelectedWhoDidWeBeat = 'On-Premise PBX';
        obj.strsectedOnPremisePBXdetail = 'Cisco';
        obj.strSelectedWhoDidWeBeat1 = 'Hosted PBX';
        obj.strsectedHostedPBXdetail1 = 'Mitel'; 
         obj.toShowImplementationAppointment(Oppval12) ;   
        obj.getImplementationContact(Oppval12);      
        obj.OpportunityUpdate();
        Test.stopTest();
    }
}