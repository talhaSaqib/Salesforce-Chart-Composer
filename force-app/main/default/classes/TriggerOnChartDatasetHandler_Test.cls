@isTest
public with sharing class TriggerOnChartDatasetHandler_Test {

    @TestSetup
    static void makeData() {
        Chart__c c = new Chart__c();
        c.Name = 'Test Chart';
        insert c;
    }

    @isTest 
    public static void testValidateDatasetFields() {
        TriggerOnChartDatasetHandler handler = new TriggerOnChartDatasetHandler();
        Boolean result;

        Chart__c c = [SELECT id FROM Chart__c WHERE Name = 'Test Chart'];

        Dataset__c d1 =  new Dataset__c();
        d1.Chart__c = c.Id;
        d1.Dataset_Label__c = 'Test';
        d1.Chart_Type__c = 'bar';
        d1.Source_Object__c = 'Account';
        d1.Source_Field__c = 'Name';
        d1.Source_Label__c = 'Name';
        result = handler.validateDatasetFields(new List<Dataset__c>{ d1 });
        Assert.areEqual(false, result);

        Dataset__c d2 =  new Dataset__c();
        d2.Chart__c = c.Id;
        d2.Dataset_Label__c = 'Test';
        d2.Chart_Type__c = 'bar';
        d2.Source_Object__c = 'Account';
        d2.Source_Field__c = 'AnnualRevenue';
        d2.Source_Label__c = 'Name';
        insert d2;
        result = handler.validateDatasetFields(new List<Dataset__c>{ d2 });
        Assert.areEqual(true, result);
    }

    @isTest 
    public static void testValidateCustomSOQL() {
        TriggerOnChartDatasetHandler handler = new TriggerOnChartDatasetHandler();
        Boolean result;

        Chart__c c = [SELECT id FROM Chart__c WHERE Name = 'Test Chart'];

        Dataset__c d1 =  new Dataset__c();
        d1.Chart__c = c.Id;
        d1.Dataset_Label__c = 'Test';
        d1.Chart_Type__c = 'bar';
        d1.Use_Custom_SOQL__c = true;
        d1.SOQL__c = 'Test';
        result = handler.ValidateCustomSOQL(new List<Dataset__c>{ d1 });
        Assert.areEqual(false, result);

        Dataset__c d2 =  new Dataset__c();
        d2.Chart__c = c.Id;
        d2.Dataset_Label__c = 'Test';
        d2.Chart_Type__c = 'bar';
        d2.Use_Custom_SOQL__c = true;
        d2.SOQL__c = 'Select id from Account';
        result = handler.ValidateCustomSOQL(new List<Dataset__c>{ d2 });
        Assert.areEqual(false, result);

        Dataset__c d3 =  new Dataset__c();
        d3.Chart__c = c.Id;
        d3.Dataset_Label__c = 'Test';
        d3.Chart_Type__c = 'bar';
        d3.Use_Custom_SOQL__c = true;
        d3.SOQL__c = 'Select id, Name From Account WITH SECURITY_ENFORCED LIMIT 1';
        result = handler.ValidateCustomSOQL(new List<Dataset__c>{ d3 });
        Assert.areEqual(true, result);

        Dataset__c d4 =  new Dataset__c();
        d4.Chart__c = c.Id;
        d4.Dataset_Label__c = 'Test';
        d4.Chart_Type__c = 'bar';
        d4.Use_Custom_SOQL__c = true;
        d4.SOQL__c = 'Select id, Name, AnnualRevenue From Account WITH SECURITY_ENFORCED LIMIT 1';
        result = handler.ValidateCustomSOQL(new List<Dataset__c>{ d4 });
        Assert.areEqual(false, result);

        Dataset__c d5 =  new Dataset__c();
        d5.Chart__c = c.Id;
        d5.Dataset_Label__c = 'Test';
        d5.Chart_Type__c = 'bar';
        d5.Use_Custom_SOQL__c = true;
        d5.SOQL__c = 'Select id, Name From Account WITH SECURITY_ENFORCED';
        result = handler.ValidateCustomSOQL(new List<Dataset__c>{ d5 });
        Assert.areEqual(false, result);

        Dataset__c d6 =  new Dataset__c();
        d6.Chart__c = c.Id;
        d6.Dataset_Label__c = 'Test';
        d6.Chart_Type__c = 'bar';
        d6.Use_Custom_SOQL__c = true;
        d6.SOQL__c = 'Select id, Name From Account';
        result = handler.ValidateCustomSOQL(new List<Dataset__c>{ d6 });
        Assert.areEqual(false, result);

        Dataset__c d7 =  new Dataset__c();
        d7.Chart__c = c.Id;
        d7.Dataset_Label__c = 'Test';
        d7.Chart_Type__c = 'bar';
        d7.Use_Custom_SOQL__c = true;
        d7.SOQL__c = 'Select id, (Select id from Contact) From Account';
        result = handler.ValidateCustomSOQL(new List<Dataset__c>{ d7 });
        Assert.areEqual(false, result);
    }
}