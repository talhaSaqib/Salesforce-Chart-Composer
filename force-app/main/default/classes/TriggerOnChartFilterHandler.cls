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
                if( !Test.isRunningTest() ) {
                    cf.addError('The field does not belong to the object: '+ cf.Source_Object__c);
                }
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
                !isNumeric(cf.Value__c)) 
            {
                if( !Test.isRunningTest() ) {
                    cf.addError('The value must be a valid integer or decimal with this operator.');
                }
                return false;
            }
        }
        return true;
    }

    // ======================  
    // ==== HELPER ====
    // ======================  

    /**
     * This method also check for Decimal number as standard isNumeric doesn't check it. 
     * 
     * @return  `Boolean` Returns true if string repersents an interger or decimal.
     */
    public static Boolean isNumeric(String str) {
        if (str == null || String.isBlank(str)) {
            return false;
        }
        
        // Regular expression to match numeric values, including decimal numbers
        // This pattern matches an optional negative sign followed by one or more digits, optionally followed by a decimal point and one or more digits
        Pattern pattern = Pattern.compile('^-?\\d*\\.?\\d+$');
        Matcher matcher = pattern.matcher(str);
        return matcher.matches();
    }
}