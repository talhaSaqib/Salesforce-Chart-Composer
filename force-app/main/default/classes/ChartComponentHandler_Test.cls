/**
 * The test class for ChartComponentHandler.cls.
 * 
 * @author Talha Saqib
 * @since 20 Jan, 2024
 */
@isTest
public with sharing class ChartComponentHandler_Test {
    /**
     * Setup method responsible for test data creation.
     */
    @TestSetup
    static void makeData(){

        // Creating Chart record
        Chart__c c = new Chart__c();
        c.Chart_Type__c = 'Bar';
        c.Source_Field__c = 'NumberOfEmployees';
        c.Source_Object__c = 'Account';
        c.Source_Label__c = 'Name';
        c.Dataset_Label__c = 'Number of Employees';
        c.Earliest_Date__c =  Date.valueOf('2000-05-05');
        c.Latest_Date__c = Date.today();
        c.Records_Limit__c = 10;
        c.Sort_By__c = 'Name';
        c.Sort_Order__c = 'ASC';
        c.Relationship_Field__c = 'OwnerId';
        insert c;

        // Creating Chart Filter records
        Chart_Filter__c cf = new Chart_Filter__c();
        cf.Field__c = 'Name';
        cf.Operator__c = '!=';
        cf.Value__c = '\'Sample Value\'';
        cf.Chart__c = c.Id;
        insert cf;

        Chart_Filter__c cf1 = new Chart_Filter__c();
        cf1.Field__c = 'Name';
        cf1.Operator__c = 'NOT LIKE';
        cf1.Value__c = '\'Sample Value\'';
        cf1.Chart__c = c.Id;
        insert cf1;

        Chart_Filter__c cf2 = new Chart_Filter__c();
        cf2.Field__c = 'Name';
        cf2.Operator__c = 'NOT IN';
        cf2.Value__c = '\'Sample Value\'';
        cf2.Chart__c = c.Id;
        insert cf2;

        Chart_Filter__c cf3 = new Chart_Filter__c();
        cf3.Field__c = 'Name';
        cf3.Operator__c = 'LIKE';
        cf3.Value__c = '\'Test\'';
        cf3.Chart__c = c.Id;
        insert cf3;

        // Creating records to show in chart
        Account a = new Account();
        a.Name = 'Test';
        insert a;

        Account a1 = new Account();
        a1.Name = 'Test';
        a1.NumberOfEmployees = 1;
        insert a1;
    }

    /**
     * This test method checks if the getChartData() method is working without returning any error
     */
    @isTest
    public static void getChartData() {
        String chartId = [SELECT Chart_Id__c FROM Chart__c WHERE Source_Label__c = 'Name' Limit 1].Chart_Id__c;
        
        String jsonResponse = ChartComponentHandler.getChartData(chartId, UserInfo.getUserId());

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        String errorMessage = (String) response.get('errorMessage');
        System.debug(response);
        Assert.areEqual(null, errorMessage);
    }
}