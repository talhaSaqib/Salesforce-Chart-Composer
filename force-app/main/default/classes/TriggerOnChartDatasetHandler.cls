public with sharing class TriggerOnChartDatasetHandler {
    public TriggerOnChartDatasetHandler() {
    }

    public Boolean validateDatasetFields(List<Dataset__c> newRecords) {

        for(Dataset__c cf : newRecords) {
            SObjectType objectType = Schema.getGlobalDescribe().get(cf.Source_Object__c);

            if (objectType == null) {
                cf.addError('The source object does not exist: '+ cf.Source_Object__c);
                return false;

            } else if( !objectType.getDescribe().fields.getMap().containsKey(cf.Source_Field__c)) {
                cf.addError('The Source field ('+cf.Source_Field__c+') does not belong to the Source object: '+ cf.Source_Object__c);
                return false;

            } else if( !objectType.getDescribe().fields.getMap().containsKey(cf.Source_Label__c)) {
                cf.addError('The Source Label field ('+cf.Source_Label__c+') does not belong to the Source object: '+ cf.Source_Object__c);
                return false;
            
            } else if( !String.isBlank(cf.Sort_By__c) &&
                       !objectType.getDescribe().fields.getMap().containsKey(cf.Sort_By__c)) {
                cf.addError('The Source By field ('+cf.Sort_By__c+') does not belong to the Source object: '+ cf.Source_Object__c);
                return false;
            }
        }
        return true;
    }
}