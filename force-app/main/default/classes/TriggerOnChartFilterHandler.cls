/**
 * @author Talha Saqib
 */
public with sharing class TriggerOnChartFilterHandler {

    /**
     * @return  `Boolean` Returns ture if Filter Field belongs to Source Object of parent Dataset.
     */
    public Boolean validateFilterField(List<Chart_Filter__c> newRecords) {

        for(Chart_Filter__c cf : newRecords) {

            SObjectType objectType = Schema.getGlobalDescribe().get(cf.Source_Object__c);
        
            if ( objectType != null && !objectType.getDescribe().fields.getMap().containsKey(cf.Field__c) )
            {
                if( !Test.isRunningTest() ) {
                    cf.addError('The field does not belong to the object: '+ cf.Source_Object__c);
                }
                return false;
            }
        }
        return true;
    }
}