public with sharing class TriggerOnChartDatasetHandler {

    public TriggerOnChartDatasetHandler() {
    }

    List<Schema.DisplayType> acceptedSourceFieldTypes = new List<Schema.DisplayType> {
        Schema.DisplayType.Integer,
        Schema.DisplayType.Currency,
        Schema.DisplayType.Double,
        Schema.DisplayType.Long,
        Schema.DisplayType.Percent
    };

    List<Schema.DisplayType> acceptedSourceLabelTypes = new List<Schema.DisplayType> {
        Schema.DisplayType.String,
        Schema.DisplayType.Picklist,
        Schema.DisplayType.Integer,
        Schema.DisplayType.Double,
        Schema.DisplayType.Email,
        Schema.DisplayType.Date,
        Schema.DisplayType.ID
    };

    public Boolean validateDatasetFields(List<Dataset__c> newRecords) {

        for(Dataset__c dataset : newRecords) {
            if(!dataset.Use_Custom_SOQL__c) {

                SObjectType objectType = Schema.getGlobalDescribe().get(dataset.Source_Object__c);
                Map<String, Schema.SObjectField> fieldsMap = objectType.getDescribe().fields.getMap();
                Schema.DisplayType sourceFieldType = null;
                Schema.DisplayType sourceLabelType = null;

                Boolean sourceFieldExists = fieldsMap.containsKey(dataset.Source_Field__c);
                Boolean sourceLabelExists = fieldsMap.containsKey(dataset.Source_Label__c);
                Boolean sortByIsBlank = String.isBlank(dataset.Sort_By__c);
                Boolean sortByExists = null;

                if ( !sortByIsBlank ) {
                    sortByExists = fieldsMap.containsKey(dataset.Sort_By__c);
                }
                if ( sourceFieldExists ) {
                    sourceFieldType = fieldsMap.get(dataset.Source_Field__c).getDescribe().getType();
                }
                if ( sourceLabelExists ) {
                    sourceLabelType = fieldsMap.get(dataset.Source_Label__c).getDescribe().getType();
                }

                if ( objectType == null ) {
                    dataset.addError('The Source Object does not exist: '+ dataset.Source_Object__c);
                    return false;

                } else if ( !sourceFieldExists ) {
                    dataset.addError('The Source Field ('+dataset.Source_Field__c+') does not belong to the Source Object: '+ dataset.Source_Object__c);
                    return false;

                } else if ( sourceFieldType != null &&
                            !acceptedSourceFieldTypes.contains(sourceFieldType) ) {
                    dataset.addError('The Source Field ('+dataset.Source_Field__c+') can only be of Numeric Type');
                    return false;
                
                } else if ( !sourceLabelExists ) {
                    dataset.addError('The Source Label field ('+dataset.Source_Label__c+') does not belong to the Source Object: '+ dataset.Source_Object__c);
                    return false;

                } else if ( sourceLabelType != null &&
                            !acceptedSourceLabelTypes.contains(sourceLabelType) ) {
                    dataset.addError('The Source Label ('+dataset.Source_Label__c+') is not of valid Data Type');
                    return false;

                } else if ( !sortByIsBlank &&
                        !sortByExists ) {
                    dataset.addError('The Source By field ('+dataset.Sort_By__c+') does not belong to the Source Object: '+ dataset.Source_Object__c);
                    return false;
                }
            }
        }
        return true;
    }

    public Boolean validateCustomSOQL(List<Dataset__c> newRecords) {
        return true;
    }
}