trigger TriggerOnChartFilter on Chart_Filter__c (before insert, before update) {
    TriggerOnChartFilterHandler handler = new TriggerOnChartFilterHandler();

    if(Trigger.isBefore)
    {
        handler.validateFilterField(Trigger.new);
    }
    
}