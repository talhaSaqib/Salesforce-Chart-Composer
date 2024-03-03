/**
 * The test class for ChartComponentHandler.cls.
 * 
 * @author Talha Saqib
 * @since 20 Jan, 2024
 */

@isTest
public with sharing class ChartComponentHandler_Test {

    @TestSetup
    static void makeData(){

        // Creating records to show in chart
        Account a = new Account();
        a.Name = 'Test';
        insert a;

        Account a1 = new Account();
        a1.Name = 'Test1';
        a1.NumberOfEmployees = 1;
        insert a1;

        Opportunity o = new Opportunity();
        o.Name = 'Test';
        o.TotalOpportunityQuantity = 100;
        o.StageName = 'Prospecting';
        o.CloseDate = Date.today();
        insert o;

        // Creating Chart records
        Chart__c ch = new Chart__c();
        ch.Relationship_Field__c = 'AccountId';
        ch.Name = 'Test';
        insert ch; 
        
        Chart__c ch1 = new Chart__c();
        ch1.Name = 'Test1';
        ch1.Relationship_Field__c = 'AccountId';
        insert ch1; 


    }
   
    @isTest
    public static void testGetChartData() {
        Chart__c c = [SELECT Id, Chart_Id__c FROM Chart__c WHERE Name = 'Test'];
        Account a = [SELECT Id FROM Account WHERE Name = 'Test'];

        String jsonResponse = ChartComponentHandler.getChartData(c.Chart_Id__c, null);
        String errorSubstring = 'No Dataset record';
        Boolean result  = jsonResponse.contains(errorSubstring);
        Assert.areEqual(true, result);
    }

    @isTest
    public static void testMakeResponseFromChartDatasets() {
        Chart__c c = [SELECT Id, Chart_Id__c FROM Chart__c WHERE Name = 'Test'];
        Chart__c c2 = [SELECT Id, Chart_Id__c FROM Chart__c WHERE Name = 'Test1'];
        Account a = [SELECT Id FROM Account WHERE Name = 'Test'];

        String jsonResponse;
        String errorSubstring;
        Boolean result;

        Dataset__c d = new Dataset__c();
        d.Chart__c = c.Id;
        d.Dataset_Label__c = 'Test';
        d.Chart_Type__c = 'bar';
        d.Source_Object__c = 'Opportunity';
        d.Source_Field__c = 'TotalOpportunityQuantity';
        d.Source_Label__c = 'Name';
        insert d;
        jsonResponse = ChartComponentHandler.getChartData(c.Chart_Id__c, null);
        errorSubstring = '"errorMessage":null';
        result = jsonResponse.contains(errorSubstring);
        System.debug(jsonResponse);
        Assert.areEqual(true, result);

        Dataset__c d1 = new Dataset__c();
        d1.Chart__c = c.Id;
        d1.Dataset_Label__c = 'Test';
        d1.Chart_Type__c = 'bar';
        d1.Use_Custom_SOQL__c = true;
        d1.SOQL__c = 'SELECT id, Name FROM Opportunity WITH SECURITY_ENFORCED LIMIT 10';
        insert d1;
        jsonResponse = ChartComponentHandler.getChartData(c.Chart_Id__c, a.Id);
        errorSubstring = '"errorMessage":null';
        result = jsonResponse.contains(errorSubstring);
        System.debug(jsonResponse);
        Assert.areEqual(true, result);

        Dataset__c d2 = new Dataset__c();
        d2.Chart__c = c2.Id;
        d2.Dataset_Label__c = 'Test';
        d2.Chart_Type__c = 'bar';
        d2.Source_Object__c = 'Opportunity';
        d2.Source_Field__c = 'TotalOpportunityQuantity';
        d2.Source_Label__c = 'Name';
        d2.Sort_Order__c = 'DESC';
        d2.Sort_By__c = 'TotalOpportunityQuantity';
        d2.Records_Limit__c = 1000;
        insert d2;
        Chart_Filter__c cf = new Chart_Filter__c();
        cf.Name = '1';
        cf.Dataset__c = d2.Id;
        cf.Field__c = 'TotalOpportunityQuantity';
        cf.Operator__c = '>';
        cf.Value__c = '0';
        insert cf;
        Chart_Filter__c cf1 = new Chart_Filter__c();
        cf1.Name = '1';
        cf1.Dataset__c = d2.Id;
        cf1.Field__c = 'Name';
        cf1.Operator__c = 'LIKE';
        cf1.Value__c = '\'Test\'';
        insert cf1;
        Chart_Filter__c cf2 = new Chart_Filter__c();
        cf2.Name = '1';
        cf2.Dataset__c = d2.Id;
        cf2.Field__c = 'Name';
        cf2.Operator__c = 'NOT LIKE';
        cf2.Value__c = '\'Testing\'';
        insert cf2;
        jsonResponse = ChartComponentHandler.getChartData(c2.Chart_Id__c, a.Id);
        errorSubstring = '"errorMessage":null';
        result = jsonResponse.contains(errorSubstring);
        System.debug(jsonResponse);
        Assert.areEqual(true, result);
    }
    
}
