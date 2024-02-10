/**
 * This file contains all the server-side logic for this project.
 * 
 * @author Talha Saqib
 * @since 25 November, 2023
 */
public with sharing class ChartComponentHandler {

    /**
     * The main method that gets all the relevant data required to render the chart.
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

                ChartComponentHandler.Dataset tempDataset = new ChartComponentHandler.Dataset();
                tempDataset.chartType = dataset.Chart_Type__c;
                tempDataset.datasetLabel = dataset.Dataset_Label__c;
                tempDataset.backgroundColor = dataset.Background_Color__c;
                tempDataset.borderColor = dataset.Border_Color__c;
                tempDataset.borderWidth = (Integer) dataset.Border_Width__c;

                String query;
                if( dataset.Filter_Requirements__c == 'Custom' &&
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
                                                    response);
                }

                if(query != null) {

                    // Parsing the records and segregating the data and labels.
                    List<sObject> recordsList = Database.Query(query);
                    System.debug(query);
                    System.debug('Query Results = ' + recordsList);

                    List<String> labels = new List<String>();
                    List<Object> data = new List<Object>();

                    String sourceLabel;
                    String sourceField;
                
                    if(dataset.Filter_Requirements__c == 'Custom') {
                        List<String> sourceFieldLabel = extractSoruceFieldAndLabelFromSOQL(query, response);
                        if(sourceFieldLabel == null) {
                            return;
                        }
                        sourceLabel = sourceFieldLabel[0];
                        sourceField = sourceFieldLabel[1];
                    } else {
                        sourceLabel = dataset.Source_Label__c;
                        sourceField = dataset.Source_Field__c;
                    }
        
                    for(sObject record : recordsList) {
                        try {
                            String label;
                            Object dataValue;

                            if(sourceLabel.contains('.')) {
                                label = (String) getValueFromRelationshipQuery(record, sourceLabel);
                            } else {
                                label = (String) record.get(sourceLabel);
                            }

                            if(sourceField.contains('.')) {
                                dataValue = getValueFromRelationshipQuery(record, sourceField);
                            } else {
                                dataValue = record.get(sourceField);
                            }
        
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
            response.errorMessage = 'No Dataset record found for this Chart. Please make sure that you have at least 1 dataset.';
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
                if(recordsLimit != null) {
                    if(recordsLimit < 0) {
                        response.errorMessage = 'The records limit should not be less than 0.';
                        return null;
                    } else {
                        query += ' LIMIT ' + recordsLimit;
                    }
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
     * This method is a helper method that also composes and validates SOQL query. It handles only Static Filters.
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
        if(!String.isBlank(relationField)) {
            if(noFilterApplied) {
                query += ' WHERE ';
            } else {
                query += ' AND ';
            }
            noFilterApplied = false;
            query += String.escapeSingleQuotes(relationField) + '= \'' + recordId + '\'';

            if(!tryQuery(query)) {
                System.debug(query);
                response.errorMessage = 'The input for Relationship Field is incorrect or the chart is not placed in a Record Page. Please make sure that '+ relationField +' is a valid API name of the field that exists in the Source Object. ';
                return null;
            }
        }

        // Validatiion with Dynamic Filters
        query = getFiltersAndValidateQuery(noFilterApplied,
                                            query,
                                            datasetId,
                                            filterRequirement,
                                            response);
        return query;                                      
    } 

    /**
     * This method is a helper method that also composes and validates SOQL query. It handles only Dynamic Filters.
     * 
     * @return  `String` Returns either a valid SOQL query or null.
     */
    private static String getFiltersAndValidateQuery(Boolean noFilterApplied,
                                                    String query,
                                                    String datasetId,
                                                    String filterRequirement,
                                                    ChartComponentHandler.Chart response) {
        List<Chart_Filter__c> filters = [SELECT
                                            Field__c,
                                            Operator__c,
                                            Value__c
                                        FROM
                                            Chart_Filter__c
                                        WHERE
                                            Dataset__c = :datasetId];

        for(Chart_Filter__c f : filters) {
            if(noFilterApplied) {
                query += ' WHERE ';
            } else {
                // ENCLOSE THESE FILTERS IN BRACKETS

                if(filterRequirement == 'AND' || filterRequirement == 'OR' ) {
                    query += ' '+filterRequirement+' ';
                }
            }

            if(f.Operator__c == 'LIKE') {
                // Adding wildcard % to value
                String str = f.Value__c;
                String valueWithWildCard = '\'%' + str.substring(1, str.length() - 1) + '%\'';

                query += String.escapeSingleQuotes(f.Field__c) +' '
                        + String.escapeSingleQuotes(f.Operator__c) +' '
                        + valueWithWildCard;
            
            } else if(f.Operator__c == 'NOT LIKE') {
                 // Adding wildcard % to value
                 String str = f.Value__c;
                 String valueWithWildCard = '\'%' + str.substring(1, str.length() - 1) + '%\'';
                 
                query += '(NOT '
                        + String.escapeSingleQuotes(f.Field__c) +' '
                        + 'LIKE '
                        + valueWithWildCard
                        + ')';

            } else {
                query += String.escapeSingleQuotes(f.Field__c) +' '
                        + String.escapeSingleQuotes(f.Operator__c) +' '
                        + f.Value__c;
            }
            noFilterApplied = false;

            if(!tryQuery(query)) {
                System.debug(query);
                response.errorMessage = 'The following filter is incorrect. ' + f.Field__c +' '+ f.Operator__c +' '+ f.Value__c + '.';
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

    private static String validateCustomSOQL(String SOQL,
                                            String relationField,
                                            String recordIdWhereChartis,
                                            ChartComponentHandler.Chart response) {

        String query = SOQL.toLowerCase();                                        
        if(!String.isBlank(relationField)) {

            String separator;

            if(query.contains(' with ')) {
                separator = 'with';

            } else if(query.contains(' group by ')) {
                 separator = 'group by';
            
            } else if(query.contains(' order by ')) {
                separator = 'order by';

            } else if(query.contains(' limit ')) {
                separator = 'limit';

            } else if(query.contains(' offset ')) {
                separator = 'offset';
            }

            String queryBefore = query.substringBefore(separator);
            String queryAfter = query.substringAfter(separator);

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
        }
        catch(Exception ex) {
            System.debug(ex);
            response.errorMessage = 'Custom SOQL ('+ query +') is invalid. Error: ' + ex.getMessage();
            return null;
        } 
    }

    private static List<String> extractSoruceFieldAndLabelFromSOQL(String query,
                                                                   ChartComponentHandler.Chart response) {
        query = query.toLowerCase();
        query = query.substringBetween('select', 'from');
        List<String> sourceFieldLabel = query.split(',', 2);

        List<String> returnList = new List<String>();
        try{
            returnList.add(sourceFieldLabel[0].trim());
            returnList.add(sourceFieldLabel[1].trim());
            return returnList;

        } catch(Exception ex) {
            response.errorMessage = 'Invalid Source Label or Source Field in SOQL. Please make sure that in Custom SOQL, first field rerpresents Source Label and second field represents Source Field. E.g. Select Name, AnnualRevenue From Account.';
            return null;
        }
    }

    private static Object getValueFromRelationshipQuery(SObject record, String path) {
        try {
            
          SObject temp = record;
          String[] parts = path.split('\\.');

          while(parts.size() > 1) {
            temp = temp.getSObject(parts.remove(0));
          }

          return temp.get(parts[0]);

        } catch(Exception e) {
          return null;
        }
      }

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

    public class Dataset {
        private String chartType;
        private String datasetLabel;
        private List<Object> data;
        private String backgroundColor;
        private String borderColor;
        private Integer borderWidth;
    }
}