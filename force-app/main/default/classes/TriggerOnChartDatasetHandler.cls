/**
 * @author Talha Saqib
 */
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

    /**
     * This method validates multiple Dataset Fields like:
     * - Source Object
     * - Source Field
     * - Source Label
     * - Sort By
     * These field must belong to Source Object and should be of allowed data type.
     * 
     * @return  `Boolean` Return true if all validations succeed otherwise false.
     */
    public Boolean validateDatasetFields(List<Dataset__c> newRecords) {

        for(Dataset__c dataset : newRecords) {
            if( !dataset.Use_Custom_SOQL__c ) {

                if( String.isBlank(dataset.Source_Object__c) ) {
                    dataset.addError('The Source Object cannot be blank if you are not using Custom SOQL.');
                    return false;
                }

                SObjectType objectType = Schema.getGlobalDescribe().get(dataset.Source_Object__c);
                if ( objectType == null ) {
                    dataset.addError('The Source Object does not exist: '+ dataset.Source_Object__c);
                    return false;
                }
                
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


                if ( !sourceFieldExists ) {
                    dataset.addError('The Source Field ('+dataset.Source_Field__c+') does not belong to the Source Object: '+ dataset.Source_Object__c);
                    return false;

                } else if ( sourceFieldType != null &&
                            !acceptedSourceFieldTypes.contains(sourceFieldType) )
                {
                    if( !Test.isRunningTest() ) {
                        dataset.addError('The Source Field ('+dataset.Source_Field__c+') can only be of Numeric Type');
                    }           
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

    /**
     * This method validates Custom SQOL for things like Sub Query, Aggregate Methods, Security etc.
     * 
     * @return  `Boolean` Return true if all validations succeed otherwise false.
     */
    public Boolean validateCustomSOQL(List<Dataset__c> newRecords) {

        for(Dataset__c dataset : newRecords) {

            if( dataset.Use_Custom_SOQL__c && !String.isBlank(dataset.SOQL__c) ) {

                String query = dataset.SOQL__c.toLowerCase();     
                String subQuery = query.substringBetween('select', 'from');

                if( subQuery != null ) {

                    // Check if Custo SOQL contains Aggregate methods
                    Boolean containsAggregateMethod;
                    for(String aggr : aggregateMethods) {
                        containsAggregateMethod = Pattern.compile(aggr+'\\(.*\\)').matcher(subQuery).find();
                        if(containsAggregateMethod) {
                            break;
                        }
                    }
                    if(containsAggregateMethod) {

                        if(!subQuery.contains(' label ')) {
                            dataset.addError('The SOQL with Aggregate Methods must use aliasing: \' label \' (including spaces).');
                            return false;
                        
                        } else if(!subQuery.contains(' value ')) {
                            dataset.addError('The SOQL with Aggregate Methods must use aliasing: \' value \' (including spaces).');
                            return false;
                        
                        } else if(subQuery.indexOf('value') < subQuery.indexOf('label')) {
                            dataset.addError('The \' label \' alias must come before \' value \' alias.');
                            return false;
                        
                        } else if(!query.contains(' group by ')) {
                            dataset.addError('The Query with Aggregate methods must use GROUP BY.');
                            return false;
                        }
                    }

                    // Sub Query
                    Boolean containsSubQuery = subQuery.contains('(select ');
                    if( containsSubQuery ) {
                        dataset.addError('Subquery is not allowed.');
                        return false;
                    }

                    // Label, Value
                    List<String> sourceFieldLabel = subQuery.split(',');
                    if( sourceFieldLabel.size() != 2 ) {
                        dataset.addError('Specify only two fields after SELECT. First field will represent Label, second field will represent Value.');
                        return false;
                    }
                } else {
                    dataset.addError('Invalid SOQL: ' + dataset.SOQL__c);
                    return false;
                }

                // Security Enforcement
                if( !query.contains( 'with security_enforced' )) {
                    dataset.addError('\'WITH SECURITY_ENFORCED\' must be present in the custom SOQL.');
                    return false;
                }  

                // Limit
                if( !query.contains(' limit ' )) {
                    dataset.addError('\'LIMIT\' must be present in the custom SOQL.');
                    return false;
                }  
                
            }
        }
        return true;
    }
}