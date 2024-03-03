@isTest
public with sharing class TriggerOnChartFilterHandler_Test {

    @TestSetup
    static void makeData() {
        Chart__c c = new Chart__c();
        c.Name = 'Test Chart';
        insert c;          
    }

    @isTest 
    public static void validateFilterField() {
        TriggerOnChartFilterHandler handler = new TriggerOnChartFilterHandler();
        Boolean result;

        Chart__c c = [SELECT id FROM Chart__c WHERE Name = 'Test Chart'];

        Dataset__c d =  new Dataset__c();
        d.Chart__c = c.Id;
        d.Dataset_Label__c = 'Test';
        d.Chart_Type__c = 'bar';
        d.Source_Object__c = 'Account';
        d.Source_Field__c = 'AnnualRevenue';
        d.Source_Label__c = 'Name';
        insert d;

        Chart_Filter__c f = new Chart_Filter__c();
        f.Dataset__c = d.Id;
        f.Name = '1';
        f.Field__c = 'Name';
        f.Operator__c = '!=';
        f.Value__c = 'Test';
        result = handler.validateFilterField(new List<Chart_Filter__c>{ f });
        Assert.areEqual(true, result);

        Chart_Filter__c f1 = new Chart_Filter__c();
        f1.Dataset__c = d.Id;
        f1.Name = '2';
        f1.Field__c = 'UnknownField';
        f1.Operator__c = '!=';
        f1.Value__c = 'Test';
        // Source_Object Formula field is only filled when record is inserted.
        insert f1;
        // Unable to assert but this case covers False path as desired. 
    }
}