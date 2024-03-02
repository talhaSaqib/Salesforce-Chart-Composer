/**
 * This file contains all the server-side logic for this project. As such, the retrieval of Chart related data,
 * composing SOQL dynamically, verifying the query and sending back a response client side that process the data 
 * and render chart.
 * 
 * @author Talha Saqib
 * @since 25 November, 2023
 */
public with sharing class ChartComponentHandler {

    // ============================================    
    // ==== QUERY COMPOSITION VIA SF OBJECTS ====
    // ============================================    

    /**
     * The main method that gets all the Chart data and makes Chart Response from Datasets.
     * 
     * @param chartId This is not Id field but a custom auto-number field.
     * @param recordId The id of the record on which the component is present. It can be null.
     * @return  `String` The JSON string that contains the Chart response structured as Chart Class.
     */
    @AuraEnabled
    public static String getChartData(String chartId, String recordIdWhereChartIs) {

        ChartComponentHandler.Chart response = new ChartComponentHandler.Chart();
        response.datasets = new List<ChartComponentHandler.Dataset>();

        List<Chart__c> chartData = [SELECT
                                        Id,
                                        Name,
                                        Relationship_Field__c
                                    FROM
                                        Chart__c
                                    WHERE
                                        Chart_Id__c = :chartId
                                    LIMIT 1];

        if(chartData.size() > 0) {

            // Setting values for Chart response
            Chart__c chartAttributes = chartData[0];
            response.chartTitle = chartAttributes.Name;
            response.chartRecordId = chartAttributes.Id;

            makeResponseFromChartDatasets(  chartAttributes.Id,
                                            chartAttributes.Relationship_Field__c,
                                            response,
                                            recordIdWhereChartIs);
            
        } else {
            response.errorMessage = 'No Chart record found for the specified Chart Id. Please make sure that you have entered a valid Chart Id.';
        }

        return JSON.serialize(response);
    }

    /**
     * This method gets data from Datasets records and compiles the response for client-side.
     */
    private static void makeResponseFromChartDatasets(  String chartRecordId,
                                                        String relationshipField,
                                                        ChartComponentHandler.Chart response,
                                                        String recordIdWhereChartIs) {

        List<Dataset__c> datasetsList = [SELECT 
                                            Id,
                                            Chart_Type__c,	
                                            Source_Field__c,
                                            Source_Object__c,
                                            Source_Label__c,
                                            Dataset_Label__c,

                                            Records_Limit__c,
                                            Sort_By__c,
                                            Sort_Order__c,
                                            Earliest_Date__c,
                                            Latest_Date__c,
                                            Filter_Requirements__c,
                                            Use_Custom_SOQL__c,
                                            Custom_Filters_Logic__c,

                                            SOQL__c,

                                            Background_Color__c,
                                            Border_Color__c,
                                            Border_Width__c
                                        FROM
                                            Dataset__c
                                        WHERE
                                            Chart__c = :chartRecordId
                                        ];
        
        if(datasetsList.size() > 0) {

            for(Dataset__c dataset : datasetsList) {

                // Setting basic Dataset values
                ChartComponentHandler.Dataset tempDataset = new ChartComponentHandler.Dataset();
                tempDataset.chartType = dataset.Chart_Type__c;
                tempDataset.datasetLabel = dataset.Dataset_Label__c;
                tempDataset.backgroundColor = dataset.Background_Color__c;
                tempDataset.borderColor = dataset.Border_Color__c;
                tempDataset.borderWidth = (Integer) dataset.Border_Width__c;

                String query;
                if( dataset.Use_Custom_SOQL__c &&
                    !String.isBlank(dataset.SOQL__c) ) {

                    // Validating Custom SOQL
                    query = validateCustomSOQL( dataset.SOQL__c,
                                                relationshipField,
                                                recordIdWhereChartIs,
                                                response);

                } else {
                    // Composing and validating SOQL
                    query = validateAndComposeQuery( dataset.Source_Field__c,
                                                    dataset.Source_Label__c,
                                                    dataset.Source_Object__c,
                                                    relationshipField,
                                                    
                                                    (Integer) dataset.Records_Limit__c,
                                                    dataset.Sort_By__c,
                                                    dataset.Sort_Order__c,
                                                    String.valueOf(dataset.Earliest_Date__c),
                                                    String.valueOf(dataset.Latest_Date__c),
                                                    
                                                    recordIdWhereChartIs,
                                                    dataset.Id,
                                                    dataset.Filter_Requirements__c,
                                                    dataset.Custom_Filters_Logic__c,	
                                                    response);
                }

                if(query != null) {

                    // Parsing the records and segregating the data and labels.
                    System.debug(query);
                    List<sObject> recordsList = Database.Query(query);
                    System.debug('Query Results = ' + recordsList);

                    List<String> labels = new List<String>();
                    List<Object> data = new List<Object>();

                    String sourceLabel;
                    String sourceField;
                
                    // For Custom SOQL Field and Label are extracted differently
                    if(dataset.Use_Custom_SOQL__c) {
                        List<String> sourceFieldLabel = extractSoruceFieldAndLabelFromSOQL(query, response);
                        if(sourceFieldLabel == null) {
                            return;
                        }
                        sourceLabel = sourceFieldLabel[0];
                        sourceField = sourceFieldLabel[1];
                    
                    // For non-custom SOQL 
                    } else {
                        sourceLabel = dataset.Source_Label__c;
                        sourceField = dataset.Source_Field__c;
                    }
        
                    for(sObject record : recordsList) {
                        try {
                            String label;
                            Object dataValue;

                            label = (String) getValueFromRelationshipQuery(record, sourceLabel);
                            dataValue = getValueFromRelationshipQuery(record, sourceField);
        
                            // Collecting Label Values
                            if(String.isBlank(label)) {
                                labels.add('');
                            } else {
                                labels.add(label);
                            }
        
                            // Collecting Dataset Values
                            if(dataValue == null) {
                                data.add(0);
                            } else {
                                data.add(dataValue);
                            }

                        } catch(Exception ex) {
                            System.debug(ex);
                            response.errorMessage = 'Compiled SOQL ('+ query +') is invalid. Error: ' + ex.getMessage();
                            return;
                        }
                    }
        
                    response.labels = labels;
                    tempDataset.data = data;
                }

                response.datasets.add(tempDataset);
            }

        } else {
            response.errorMessage = 'No Dataset record found for this Chart. Please make sure that you have at least one dataset.';
        }
    }

    /**
     * This method composes a SOQL query in multiple steps and at each step validates the query
     * to validate and send respective errors to client.
     * 
     * @return  `String` Returns either a valid SOQL query or null.
     */
    private static String validateAndComposeQuery(String sourceField,
                                        String sourceLabel,
                                        String sourceObject,
                                        String relationField,
                                        Integer recordsLimit,
                                        String sortBy,
                                        String sortOrder,
                                        String earliestDate,
                                        String latestDate,
                                        String recordId,
                                        String datasetId,
                                        String filterRequirement,
                                        String customFiltersLogic,
                                        ChartComponentHandler.Chart response) {
        // Validating Source Object
        String slct = 'SELECT ';
        String fields = 'id';
        String fromObj = ' FROM ' + sourceObject;
        String query = slct + fields + fromObj;
        if(tryQuery(query)) {

            // Validating Source Label and Source Field
            fields = sourceField + ', ' + sourceLabel;
            query = slct + fields + fromObj;
            if(tryQuery(query)) {

                // Validating Filters
                query = validateAndComposeQueryWithFilters(query,
                                                earliestDate,
                                                latestDate,
                                                relationField,
                                                recordId,
                                                datasetId,
                                                filterRequirement,
                                                customFiltersLogic,
                                                response);
                if(query == null) {
                    return null;
                }

                // Adding Security Enforced
                query += ' WITH SECURITY_ENFORCED ';

                // Validating Order By Field
                if(!String.isBlank(sortBy)) {
                    if(!String.isBlank(sortOrder)) {
                        query += ' ORDER BY ' + String.escapeSingleQuotes(sortBy) + ' ' + String.escapeSingleQuotes(sortOrder) + ' NULLS LAST';
                    } else {
                        query += ' ORDER BY ' + String.escapeSingleQuotes(sortBy) + ' NULLS LAST';
                    }
                    if(!tryQuery(query)) {
                        System.debug(query);
                        response.errorMessage = 'The input for Sort By field is incorrect. Please make sure that '+ sortBy +' is a valid API name of the field that exists in the Source Object.';
                        return null;
                    }
                }

                // Validating Limit
                if(recordsLimit == null) {
                    response.errorMessage = 'The records limit cannot be null.';
                    return null;

                } else if(recordsLimit < 0 || recordsLimit > 500000) {
                    response.errorMessage = 'The records limit should be between 0 and 500000.';
                    return null;

                } else {
                    query += ' LIMIT ' + recordsLimit;
                }
            
                return query;

            } else {
                System.debug(query);
                response.errorMessage = 'The input for Soruce Label or Source Field is incorrect. Please check these fields in the ' + sourceObject + ' object and make sure the API names are correct and that user has access to fields.';
                return null;
            }
        } else {
            System.debug(query);
            response.errorMessage = 'The Source Object ' + sourceObject + ' does not exist. Please check the object API name and access settings.';
            return null;
        }
    }

    /**
     * This method is a helper method that also composes and validates SOQL query. It handles only basic Filters that are 
     * present on Dataset Record and Chart Record.
     * 
     * @return  `String` Returns either a valid SOQL query or null.
     */
    private static String validateAndComposeQueryWithFilters(String query,
                                                  String earliestDate,
                                                  String latestDate,
                                                  String relationField,
                                                  String recordId,
                                                  String datasetId,
                                                  String filterRequirement,
                                                  String customFiltersLogic,
                                                  ChartComponentHandler.Chart response) {
        Boolean noFilterApplied = false;

        // Validating Earliest and Latest Date
        if(earliestDate != null && latestDate != null) {
            query += ' WHERE DAY_ONLY(CreatedDate) >= ' + earliestDate + ' AND DAY_ONLY(CreatedDate) <= ' + latestDate;
        
        } else if(earliestDate == null && latestDate != null) {
            query += ' WHERE DAY_ONLY(CreatedDate) <= ' + latestDate;
        
        } else if(earliestDate != null && latestDate == null) {
            query += ' WHERE DAY_ONLY(CreatedDate) >= ' + earliestDate;
        
        } else {
            noFilterApplied = true;
        }
        if(!tryQuery(query)) {
            System.debug(query);
            response.errorMessage = 'Error in validating Earliest and Latest Date fields.';
            return null;
        }

        // Validating Relationship Field
        if(!String.isBlank(relationField) && !String.isBlank(recordId)) {
            if(noFilterApplied) {
                query += ' WHERE ';
            } else {
                query += ' AND ';
            }
            noFilterApplied = false;
            query += String.escapeSingleQuotes(relationField) + '= \'' + recordId + '\'';

            if(!tryQuery(query)) {
                System.debug(query);
                response.errorMessage = 'The input for Relationship Field is incorrect or the chart is not placed in a Record Page. Please make sure that '+ relationField +' is a valid API name of the field that exists in the Source Object.';
                return null;
            }
        }

        // Validation with Dynamic Filters
        query = getFiltersAndValidateQuery(noFilterApplied,
                                            query,
                                            datasetId,
                                            filterRequirement,
                                            customFiltersLogic,
                                            response);
        return query;                                      
    } 

    /**
     * This method is a helper method that also composes and validates SOQL query. It handles filters that are from
     * Filter related records.
     * 
     * @return  `String` Returns either a valid SOQL query or null.
     */
    private static String getFiltersAndValidateQuery(Boolean noFilterApplied,
                                                    String query,
                                                    String datasetId,
                                                    String filterRequirement,
                                                    String customFiltersLogic,
                                                    ChartComponentHandler.Chart response) {
        List<Chart_Filter__c> filtersList = [SELECT
                                            Name,
                                            Field__c,
                                            Operator__c,
                                            Value__c
                                        FROM
                                            Chart_Filter__c
                                        WHERE
                                            Dataset__c = :datasetId];

        if(filtersList.size() > 0) {
            if(noFilterApplied) {
                query += ' WHERE (FILTERS)';
            } else {
                query += ' AND (FILTERS)';
            }

            Map<String, String> filtersMap = new Map<String, String>();
            for(Chart_Filter__c f : filtersList) {
                String filterString;

                if(f.Operator__c == 'LIKE') {
                    // Adding wildcard % to value
                    String str = f.Value__c;
                    String valueWithWildCard = '\'%' + str.substring(1, str.length() - 1) + '%\'';
    
                    filterString = String.escapeSingleQuotes(f.Field__c) +' '
                            + String.escapeSingleQuotes(f.Operator__c) +' '
                            + valueWithWildCard;
                
                } else if(f.Operator__c == 'NOT LIKE') {
                     // Adding wildcard % to value
                    String str = f.Value__c;
                    String valueWithWildCard = '\'%' + str.substring(1, str.length() - 1) + '%\'';
                     
                    filterString = '(NOT '
                            + String.escapeSingleQuotes(f.Field__c) +' '
                            + 'LIKE '
                            + valueWithWildCard
                            + ')';
    
                } else {
                    filterString = String.escapeSingleQuotes(f.Field__c) +' '
                            + String.escapeSingleQuotes(f.Operator__c) +' '
                            + f.Value__c;
                }

                filtersMap.put(f.Name, filterString); 
            }

            String filters;
            // AND, OR
            if(filterRequirement != 'Custom') {
                String delimiter = ' '+filterRequirement+' '; 
                filters = String.join(filtersMap.values(), delimiter); 
            
            // CUSTOM
            } else {

                // Replacing Filter Names with actial Query Files
                for (String filterName : filtersMap.keySet()) {
                    customFiltersLogic = customFiltersLogic.replace(filterName, filtersMap.get(filterName));
                }
                filters = customFiltersLogic;
            }
            query = query.replace('FILTERS', filters);

            // Testing the query
            try{
                Database.Query(query + ' LIMIT 0');
                return query;
            }
            catch(QueryException ex) {
                System.debug(ex);
                response.errorMessage = 'Error in compiling Filters: ' + ex.getMessage();
                return null;
            }
        }  
        return query;                                                     
    }

    /**
     * This method runs the input SOQL query to see if it is valid or not.
     * 
     * @return  `Boolean` Returns true if query ran successfully, false if it failed.
     */
    private static Boolean tryQuery(String query) {
        try{
            Database.Query(query + ' LIMIT 0');
            return true;
        }
        catch(QueryException ex) {
            System.debug(ex);
            return false;
        }
    }


    // ======================  
    // ==== CUSTOM SOQL ====
    // ======================   

    /**
     * This method validates the Custom SOQL input by user.
     * 
     * @return  `String` Returns quert or null depending on the validation.
     */
    private static String validateCustomSOQL(String SOQL,
                                            String relationField,
                                            String recordIdWhereChartis,
                                            ChartComponentHandler.Chart response) {

        String query = SOQL.toLowerCase();                                        
        if(!String.isBlank(relationField)) {

            // Custom SOQL will always have WITH SECURITY_ENFORCED
            String separator;
            if(query.contains(' with ')) {
                separator = 'with';
            } 

            String queryBefore = query.substringBefore(separator);
            String queryAfter = query.substringAfter(separator);

            // Adding Relation Field on Chart record
            if(queryBefore.contains(' where ')) {
                queryBefore += ' and ' + relationField + '= \'' + recordIdWhereChartis + '\'';
            } else {
                queryBefore += ' where ' + relationField + '= \'' + recordIdWhereChartis + '\'';
            }

            query = queryBefore + ' ' + separator + ' ' + queryAfter;
        }

        try{
            Database.Query(query);
            return query;
    
        } catch(Exception ex) {
            System.debug(ex);
            response.errorMessage = 'Custom SOQL ('+ query +') is invalid. Error: ' + ex.getMessage();
            return null;
        }  
    }

    /**
     * This method parses the custom SOQL and extracts the Label and Field. If query has less than or more than 2 fields before FROM, either
     * the validation fails or the code gives error in other method.
     * 
     * @return  `List<String>` Return a list of string with size of 2, containg Label and Field for Chart or Returns null
     * if parsing fails.
     */
    private static List<String> extractSoruceFieldAndLabelFromSOQL(String query,
                                                                   ChartComponentHandler.Chart response) {
        query = query.toLowerCase();
        query = query.substringBetween('select', 'from');

        // Only 2 Field attributes are allowed between SELECT and FROM.
        List<String> sourceFieldLabel = query.split(',', 2);
        List<String> returnList = new List<String>();

        try{
            returnList = handleQueryFieldValueExtraction(sourceFieldLabel);
            return returnList;

        } catch(Exception ex) {
            response.errorMessage = 'Invalid Source Label or Source Field in SOQL. Please make sure that in Custom SOQL, first field rerpresents Source Label and second field represents Source Field. E.g. Select Name, AnnualRevenue From Account.';
            return null;
        }
    }

    /**
     * This method handles the extraction of Source Field and Source Label from query (both regular and aggregate).
     * 
     * @param fieldAndLabel The list that comes from splitting the query between SELECT and FROM by comma (,). It
     * should have only 2 entries: Label and Field
     * 
     * @return  `List<String>` This contains the actual text for Label and Field. Should be two entries.
     */
    private static List<String> handleQueryFieldValueExtraction(List<String> fieldAndLabel) {

        List<String> sourceFieldLabel = new List<String>();
        for(String str : fieldAndLabel) {

            if(str.contains('label')) {
                sourceFieldLabel.add('label');

            } else if(str.contains('value')) {
                sourceFieldLabel.add('value');
            
            } else {
                 sourceFieldLabel.add(str.trim());
            }
        }
        return sourceFieldLabel;
    }


    /**
     * This method parses relationship query and returns the desired value e.g. it will parese Account.Contact.Id 
     * and will return 'Id' as value.
     * 
     * @param path This will be the complete relationship part e.g. Account.Contact.Id
     * @return  `Object` Returns dynamic value
     */
    private static Object getValueFromRelationshipQuery(SObject record, String path) {
        try {
            SObject temp = record;
            String[] parts = path.split('\\.');

            while( parts.size() > 1 ) {
                // Used to retrieve a related SObject from a parent SObject based on a specified relationship name.
                temp = temp.getSObject(parts.remove(0));
            }

            return temp.get(parts[0]);

        } catch(Exception e) {
          return null;
        }
      }



    // ======================  
    // ==== STRUCTS ====
    // ======================  

    /**
     * The structure for the JSON response that will contain all chart data.
     */
    public class Chart {
        private String errorMessage = null;
        private String chartTitle;
        private String chartRecordId;
        private List<ChartComponentHandler.Dataset> datasets;
        private List<String> labels;
    }

    /**
     * The structure for Dataset data that will be included in Chart JSON response.
     */
    public class Dataset {
        private String chartType;
        private String datasetLabel;
        private List<Object> data;
        private String backgroundColor;
        private String borderColor;
        private Integer borderWidth;
    }
}