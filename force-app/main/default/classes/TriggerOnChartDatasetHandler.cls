public with sharing class TriggerOnChartDatasetHandler {

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

    List<String> aggregateMethods = new List<String> {
        'count',
        'sum',
        'avg',
        'min',
        'max',
        'fields'
    };

    public Boolean validateDatasetFields(List<Dataset__c> newRecords) {

        for(Dataset__c dataset : newRecords) {
            if( !dataset.Use_Custom_SOQL__c ) {

                if( String.isBlank(dataset.Source_Object__c) ) {
                    dataset.addError('The Source Object cannot be blank if you are using Custom SOQL.');
                    return false;
                }

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
        for(Dataset__c dataset : newRecords) {
            if( dataset.Use_Custom_SOQL__c && !String.isBlank(dataset.SOQL__c) ) {

                String query = dataset.SOQL__c.toLowerCase();     
                String subQuery = query.substringBetween('select', 'from')?.trim();

                if( subQuery != null ) {

                    // Aggregate Methods
                    for(String aggr : aggregateMethods) {
                        Boolean containsAggregateMethod = Pattern.compile(aggr+'\\(.*\\)').matcher(subQuery).find();
                        if(containsAggregateMethod) {
                            dataset.addError('Aggregate Methods are not allowed.');
                        }
                    }

                    // Sub Query
                    Boolean containsSubQuery = subQuery.contains('(select ');
                    if( containsSubQuery ) {
                        dataset.addError('Subquery is not allowed.');
                    }

                    // Label, Value
                    List<String> sourceFieldLabel = subQuery.split(',');
                    if( sourceFieldLabel.size() != 2 ) {
                        dataset.addError('Specify only two fields after SELECT. First field will represent Label, second field will represent Value.');
                    }
                }

                // Security Enforcement
                if( !query.contains('with security_enforced' )) {
                    dataset.addError('\'WITH SECURITY_ENFORCED\' must be present in the custom SOQL.');
                }        
            }
        }
        return true;
    }
}