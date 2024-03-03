trigger TriggerOnChartDataset on Dataset__c (before insert, before update) {
    TriggerOnChartDatasetHandler handler = new TriggerOnChartDatasetHandler();

    if(Trigger.isBefore)
    {
        handler.validateDatasetFields(Trigger.new);
        handler.validateCustomSOQL(Trigger.new);
    }
}