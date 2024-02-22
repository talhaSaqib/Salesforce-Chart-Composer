public with sharing class TriggerOnChartFilterHandler {

    List<String> numericOperators = new List<String> {'>', '<', '>=', '<='};
    List<String> stringOperators = new List<String> {'LIKE', 'NOT LIKE'};

    /**
     * @return  `Boolean` Returns ture if Filter Field belongs to Source Object of parent Dataset.
     */
    public Boolean validateFilterField(List<Chart_Filter__c> newRecords) {

        for(Chart_Filter__c cf : newRecords) {

            SObjectType objectType = Schema.getGlobalDescribe().get(cf.Source_Object__c);
            
            if ( objectType != null &&
                 !objectType.getDescribe().fields.getMap().containsKey(cf.Field__c) )
            {
                cf.addError('The field does not belong to the object: '+ cf.Source_Object__c);
                return false;
            }
        }
        return true;
    }

    /**
     * @return  `Boolean` Return true if Filter Operator is a numeric operator and Filter Value is also numeric.
     */
    public Boolean validateFilterValue(List<Chart_Filter__c> newRecords) {
        
        for(Chart_Filter__c cf : newRecords) {

            if( numericOperators.contains(cf.Operator__c) &&
                !cf.Value__c.isNumeric()) 
            {
                cf.addError('The value must be a number with this operator.');
                return false;
            }
        }
        return true;
    }
}