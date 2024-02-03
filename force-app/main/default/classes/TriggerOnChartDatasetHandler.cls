public with sharing class TriggerOnChartDatasetHandler {

    public TriggerOnChartDatasetHandler() {
    }

    List<Schema.DisplayType> acceptedSourceFieldTypes = new List<Schema.DisplayType> {
        Schema.DisplayType.Integer,
        Schema.DisplayType.Currency,
        Schema.DisplayType.Double,
        Schema.DisplayType.Long
    };

    public Boolean validateDatasetFields(List<Dataset__c> newRecords) {

        for(Dataset__c cf : newRecords) {
            SObjectType objectType = Schema.getGlobalDescribe().get(cf.Source_Object__c);
            Map<String, Schema.SObjectField> fieldsMap = objectType.getDescribe().fields.getMap();
            Schema.DisplayType sourceFieldType = null;
            Schema.DisplayType sourceLabelType = null;

            Boolean sourceFieldExists = fieldsMap.containsKey(cf.Source_Field__c);
            Boolean sourceLabelExists = fieldsMap.containsKey(cf.Source_Label__c);
            Boolean sortByIsBlank = String.isBlank(cf.Sort_By__c);
            Boolean sortByExists = null;

            if ( !sortByIsBlank ) {
                sortByExists = fieldsMap.containsKey(cf.Sort_By__c);
            }
            if ( sourceFieldExists ) {
                sourceFieldType = fieldsMap.get(cf.Source_Field__c).getDescribe().getType();
            }
            if ( sourceLabelExists ) {
                sourceLabelType = fieldsMap.get(cf.Source_Label__c).getDescribe().getType();
            }

            if ( objectType == null ) {
                cf.addError('The source object does not exist: '+ cf.Source_Object__c);
                return false;

            } else if ( !sourceFieldExists ) {
                cf.addError('The Source field ('+cf.Source_Field__c+') does not belong to the Source object: '+ cf.Source_Object__c);
                return false;

            } else if ( sourceFieldType != null &&
                        !acceptedSourceFieldTypes.contains(sourceFieldType) ) {
                cf.addError('The Source field ('+cf.Source_Field__c+') can only be of Numeric Type');
                return false;
            
            } else if ( !sourceLabelExists ) {
                cf.addError('The Source Label field ('+cf.Source_Label__c+') does not belong to the Source object: '+ cf.Source_Object__c);
                return false;

            } else if ( sourceLabelType != null &&
                        sourceFieldType != Schema.DisplayType.Anytype) {
                cf.addError('The Source field ('+cf.Source_Field__c+') can only be of Numeric Type');
                return false;

            } else if ( !sortByIsBlank &&
                       !sortByExists ) {
                cf.addError('The Source By field ('+cf.Sort_By__c+') does not belong to the Source object: '+ cf.Source_Object__c);
                return false;
            }
        }
        return true;
    }
}