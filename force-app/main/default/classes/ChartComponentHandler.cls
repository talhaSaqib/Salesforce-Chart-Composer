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
    public static String getChartData(String chartId, String recordId){
        ChartComponentHandler.Chart response = new ChartComponentHandler.Chart(); 

        List<Chart__c> chartData = [SELECT
                                        Id,
                                        Name,
                                        Chart_Type__c,

                                        Source_Field__c,
                                        Source_Object__c,
                                        Source_Label__c,
                                        Dataset_Label__c,
                                        Relationship_Field__c,

                                        Records_Limit__c,
                                        Sort_By__c,
                                        Sort_Order__c,
                                        Earliest_Date__c,
                                        Latest_Date__c,

                                        Background_Color__c,
                                        Border_Color__c,
                                        Border_Width__c
                                    FROM
                                        Chart__c
                                    WHERE
                                        Chart_Id__c = :chartId
                                    LIMIT 1];

        if(chartData.size() > 0) {

            // Setting values for Chart response
            Chart__c chartAttributes = chartData[0];
            response.chartTitle = chartAttributes.Name;
            response.chartType = chartAttributes.Chart_Type__c;
            response.datasetLabel = chartAttributes.Dataset_Label__c;
            response.backgroundColor = chartAttributes.Background_Color__c;
            response.borderColor = chartAttributes.Border_Color__c;
            response.borderWidth =  (Integer) chartAttributes.Border_Width__c;

            // Composing and validating SOQL
            String query = validateAndComposeQuery( String.escapeSingleQuotes(chartAttributes.Source_Field__c),
                                                    String.escapeSingleQuotes(chartAttributes.Source_Label__c),
                                                    String.escapeSingleQuotes(chartAttributes.Source_Object__c),
                                                    chartAttributes.Relationship_Field__c,
                                                    
                                                    (Integer) chartAttributes.Records_Limit__c,
                                                    chartAttributes.Sort_By__c,
                                                    chartAttributes.Sort_Order__c,
                                                    String.valueOf(chartAttributes.Earliest_Date__c),
                                                    String.valueOf(chartAttributes.Latest_Date__c),
                                                    
                                                    recordId,
                                                    chartAttributes.Id,
                                                    response);
            
            if(query != null) {

                // Parsing the records and segregating the data and labels.
                List<sObject> recordsList = Database.Query(query);
                System.debug(query);
                System.debug('Query Results = ' + recordsList);

                List<String> labels = new List<String>();
                List<Object> data = new List<Object>();
 
                for(sObject record : recordsList) {
                     String label = (String) record.get(chartAttributes.Source_Label__c);
                     Object dataValue = record.get(chartAttributes.Source_Field__c);
 
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
                 }
 
                response.labels = labels;
                response.dataset = data;
            } 
        } else {
            response.errorMessage = 'No Chart record found for the specified Chart Id. Please make sure that you have entered a valid Chart Id.';
        }

        return JSON.serialize(response);
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
                                        String chartId,
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
                                                chartId,
                                                response);
                if(query == null) {
                    return null;
                }

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
                                                  String chartId,
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
                                            chartId,
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
                                                    String chartId,
                                                    ChartComponentHandler.Chart response) {
        List<Chart_Filter__c> filters = [SELECT
                                            Field__c,
                                            Operator__c,
                                            Value__c
                                        FROM
                                            Chart_Filter__c
                                        WHERE
                                            Chart__c = :chartId];

        for(Chart_Filter__c f : filters) {
            if(noFilterApplied) {
                query += ' WHERE ';
            } else {
                query += ' AND ';
            }

            // Adding wildcard % to value
            String str = f.Value__c;
            String valueWithWildCard = '\'%' + str.substring(1, str.length() - 1) + '%\'';

            List<String> listOperators = new List<String>{'IN', 'NOT IN', 'INCLUDES', 'EXCLUDES'};
            if(listOperators.contains(f.Operator__c)) {
                query += String.escapeSingleQuotes(f.Field__c) +' '
                        + String.escapeSingleQuotes(f.Operator__c)
                        +' (' 
                        + f.Value__c
                        + ')';

            } else if(f.Operator__c == 'LIKE') {
                query += String.escapeSingleQuotes(f.Field__c) +' '
                        + String.escapeSingleQuotes(f.Operator__c) +' '
                        + valueWithWildCard;
            
            } else if(f.Operator__c == 'NOT LIKE') {
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
            Database.Query(query + ' LIMIT 1');
            return true;
        }
        catch(QueryException ex) {
            System.debug(ex);
            return false;
        }
    }

    /**
     * The structure for the JSON response that will contain all chart data.
     */
    public class Chart {
        private String errorMessage = null;
        private String chartTitle;
        private String chartType;
        private String datasetLabel;
        private List<String> labels;
        private List<Object> dataset;
        private String backgroundColor;
        private String borderColor;
        private Integer borderWidth;
    }
}