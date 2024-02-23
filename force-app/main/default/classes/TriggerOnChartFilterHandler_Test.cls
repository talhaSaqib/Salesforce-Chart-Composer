@isTest
public with sharing class TriggerOnChartFilterHandler_Test {

    @TestSetup
    static void makeData() {
        Chart__c c = new Chart__c();
        c.Name = 'Test Chart';
        insert c;

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
        insert f;

        Chart_Filter__c f1 = new Chart_Filter__c();
        f1.Dataset__c = d.Id;
        f1.Name = '2';
        f1.Field__c = 'UnknownField';
        f1.Operator__c = '!=';
        f1.Value__c = 'Test';
        insert f1;

        Chart_Filter__c f2 = new Chart_Filter__c();
        f2.Dataset__c = d.Id;
        f2.Name = '3';
        f2.Field__c = 'AnnualRevenue';
        f2.Operator__c = '>';
        f2.Value__c = '1000';
        insert f2;

        Chart_Filter__c f3 = new Chart_Filter__c();
        f3.Dataset__c = d.Id;
        f3.Name = '4';
        f3.Field__c = 'AnnualRevenue';
        f3.Operator__c = '>';
        f3.Value__c = 'Test';
        insert f3;
    }

    @isTest 
    public static void testChartFilter() {
        TriggerOnChartFilterHandler handler = new TriggerOnChartFilterHandler();
        Boolean result;
        Chart_Filter__c f;

        // Name != Test
        f = [SELECT 
                Dataset__c,
                Field__c,
                Operator__c,
                Value__c,
                Source_Object__c
            FROM
                Chart_Filter__c
            WHERE
                Name = '1'
            LIMIT 1];
        result = handler.validateFilterField(new List<Chart_Filter__c>{ f });
        Assert.areEqual(true, result);

        // UnknownField != Test
        f = [SELECT 
                Dataset__c,
                Field__c,
                Operator__c,
                Value__c,
                Source_Object__c
            FROM
                Chart_Filter__c
            WHERE
                Name = '2'
            LIMIT 1];
        result = handler.validateFilterField(new List<Chart_Filter__c>{ f });
        Assert.areEqual(false, result);

         // AnnualRevenue > 1000
         f = [SELECT 
                Dataset__c,
                Field__c,
                Operator__c,
                Value__c,
                Source_Object__c
            FROM
                Chart_Filter__c
            WHERE
                Name = '3'
            LIMIT 1];
        result = handler.validateFilterValue(new List<Chart_Filter__c>{ f });
        Assert.areEqual(true, result);

         // AnnualRevenue > Test
         f = [SELECT 
                Dataset__c,
                Field__c,
                Operator__c,
                Value__c,
                Source_Object__c
            FROM
                Chart_Filter__c
            WHERE
                Name = '4'
            LIMIT 1];
        result = handler.validateFilterValue(new List<Chart_Filter__c>{ f });
        Assert.areEqual(false, result);
    }
}