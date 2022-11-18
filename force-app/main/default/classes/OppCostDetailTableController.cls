public with sharing class OppCostDetailTableController {
    //public without sharing class OppCostDetailTableController {
    static final String  CATEGORY_FIELD_NAME = 'Category';
    static final String  TOTAL_FIELD_NAME = 'Total';
    static final String  PREVIOUS_YEARS_FIELD_NAME = 'PreviousYrs';

    static final String PROCUREMENT_PRODUCT_CODE = 'Materials';
    static final String SUBCONTRACT_PRODUCT_CODE = 'Subcontract';

    static final String PROCUREMENT_ROW_LABEL = 'Procurements:';
    static final String SUBCONTRACT_ROW_LABEL = 'Subcontracts:';
    static final String TOTAL_COST_ROW_LABEL = 'Total Cost Estimate:';

    static final Integer ZERO_ELEMENTS = 0;

    static final Integer REPORT_YEAR_COUNT = 5;


    @AuraEnabled(cacheable=true)
    public static OppCostDetailTableController.OppDetailClass getOppDetail(String oppId) {
        OppCostDetailTableController.OppDetailClass oppDetail =
            new OppCostDetailTableController.OppDetailClass();

        oppDetail.columns = OppCostDetailTableController.getColumns();
        OppCostDetailTableController.setFieldNames(oppDetail.columns);

        oppDetail.recs = OppCostDetailTableController.getRecs(oppId);

        //  setRecs(oppDetail);
        
        return oppDetail; 
    }

    private static List<String> fieldNames = new List<String>();
    private static void setFieldNames (List<Map<String, String>> columns) {
        for(Map<String, String> column : columns) {
            fieldNames.add(column.get('fieldName'));
        }
    }
    private static List<Map<String, String>> getColumns() {
        final Integer maxYear;
    
        List<Map<String, String>> retColumns = new List<Map<String, String>>();
        
        ColumnClass columnObj;

        //  Setup Default Field Objects
        columnObj = new ColumnClass();
        columnObj.fieldName = CATEGORY_FIELD_NAME;
        columnObj.label = '';
        retColumns.add(columnObj.getFieldMap());

        columnObj.fieldName = TOTAL_FIELD_NAME;
        columnObj.label = 'Total ($)';
        retColumns.add(columnObj.getFieldMap());

        columnObj = new ColumnClass();
        columnObj.fieldName = PREVIOUS_YEARS_FIELD_NAME;
        columnObj.label = 'Prior Yrs';
        retColumns.add(columnObj.getFieldMap());

        String reportYearStr;
        Integer currentYear = Date.today().year();
        maxYear = currentYear + REPORT_YEAR_COUNT;

        for(Integer reportYear=currentYear; reportYear < maxYear; reportYear++) {
            reportYearStr = String.valueOf(reportYear);
            columnObj = new ColumnClass();
            columnObj.fieldName = 'FY' + reportYearStr;
            columnObj.label = 'FY ' + reportYearStr;
            retColumns.add(columnObj.getFieldMap());
        }

        return retColumns;
    }
    private static List<Map<String, String>> getRecs(Id oppId) {
        List<Map<String, String>> listOfRowMaps = new List<Map<String, String>>();

        Map<String, OppCostDetailTableController.RowClass> mapOfRows = new Map<String, OppCostDetailTableController.RowClass>();

        List<OpportunityLineItem> lineItems = getOppLineItems(oppId);

        String rowName;
        for(OpportunityLineItem lineItem : lineItems) {
            rowName = getRowName(lineItem);
            if(!mapOfRows.containsKey(rowName)) {
                mapOfRows.put(rowName, new OppCostDetailTableController.RowClass(rowName, OppCostDetailTableController.fieldNames));
            }
            mapOfRows.get(rowName).addFiscalYrValue(lineItem);
        }

        if(mapOfRows.size() > ZERO_ELEMENTS) {
            OppCostDetailTableController.addOtherRowstoTotalRow(mapOfRows);

            listOfRowMaps.add(mapOfRows.get(PROCUREMENT_ROW_LABEL).getRowMap());
            listOfRowMaps.add(mapOfRows.get(SUBCONTRACT_ROW_LABEL).getRowMap());
            listOfRowMaps.add(mapOfRows.get(TOTAL_COST_ROW_LABEL).getRowMap());
        }

        return listOfRowMaps;
    }
    private static List<OpportunityLineItem> getOppLineItems(Id oppId) {
        List<OpportunityLineItem> retLineItems = new List<OpportunityLineItem>();
        retLineItems = [Select Fiscal_Year__c, Product2Id, ProductCode, TotalPrice FROM OpportunityLineItem WHERE OpportunityId =: oppId];
        return retLineItems;
    }
    private static String getRowName(OpportunityLineItem lineItem) {
        String retRowName;
        //  RowName is based on the ProductCode field of the Opportunity Line Item
        //  'Procurement' is ProductCode 'Materials'
        if(lineItem.ProductCode == PROCUREMENT_PRODUCT_CODE) {
            retRowName = PROCUREMENT_ROW_LABEL;
        }else if (lineItem.ProductCode == SUBCONTRACT_PRODUCT_CODE) {
            retRowName = SUBCONTRACT_ROW_LABEL;
        }else {
            retRowName = TOTAL_COST_ROW_LABEL;
        }

        return retRowName;
    }
    private static void addOtherRowstoTotalRow(Map<String, OppCostDetailTableController.RowClass> mapOfRows) {
        Decimal procurementRowColValue;
        Decimal subcontractRowColValue;
        Decimal totalRowColValue;

        for(String fieldName : OppCostDetailTableController.fieldNames) {
            if(fieldName == CATEGORY_FIELD_NAME)continue;

            procurementRowColValue = mapOfRows.get(PROCUREMENT_ROW_LABEL).getFiscalYrValue(fieldName);
            subcontractRowColValue = mapOfRows.get(SUBCONTRACT_ROW_LABEL).getFiscalYrValue(fieldName);
            totalRowColValue = mapOfRows.get(TOTAL_COST_ROW_LABEL).getFiscalYrValue(fieldName);

            mapOfRows.get(TOTAL_COST_ROW_LABEL).addFiscalYrValue(fieldName, totalRowColValue + subcontractRowColValue + procurementRowColValue);
        }
    }

    public class OppDetailClass {
        @AuraEnabled
        public List<Map<String, String>> columns {get; protected set;}
        
        @AuraEnabled
        public List<Map<String, String>> recs {get; protected set;}
    }

    private class ColumnClass {
        final String COLUMN_TYPE_TEXT = 'text';
        final String COLUMN_TYPE_CURRENCY = 'currency';

        public ColumnClass() {
            //  default column type
            this.type = COLUMN_TYPE_TEXT;
        }
        public String fieldName {
            get; 
            set {
                this.fieldName = value;
                this.label = value;

                //  field type based on the name of the column, reset from default
                setFieldType();
            }
        }
        private void setFieldType() {
            if(this.fieldName != CATEGORY_FIELD_NAME) {
                this.type = 'currency';
            }
        }
        public String label {get; set;}
        public String type {get; set;}
        public Map<String, String> getFieldMap() {
            Map<String, String> columnDefinitionMap = new Map<String, String>();

            //  default column settings
            columnDefinitionMap.put('hideDefaultActions', 'true');

            columnDefinitionMap.put('fieldName', this.fieldName);
            columnDefinitionMap.put('label', this.label);
            columnDefinitionMap.put('type', this.type);
            
            return columnDefinitionMap;
        }
    }
    private class RowClass {
        public RowClass(String rowName, List<String> fieldNames) {
            this.rowName = rowName;
            this.fieldValueMap = new Map<String, Decimal>();
            for(String fieldName : fieldNames) {
                if(fieldName == 'Category') {
                    continue;
                }
                this.fieldValueMap.put(fieldName, 0);
            }
        }

        final Integer DEFAULT_VALUE = 0;
        private Map<String, Decimal> fieldValueMap;
        private String rowName;

        public void addFiscalYrValue(OpportunityLineItem lineItem) {
            String fieldName = getFiscalFieldName(lineItem);
            Decimal lineFieldValue = getFiscalFieldValue(lineItem);

            Decimal currentFieldValue = this.fieldValueMap.get(fieldName);

            this.fieldValueMap.put(fieldName, currentFieldValue + lineFieldValue);
        }

        public void addFiscalYrValue(String fieldName, Decimal value) {
            this.fieldValueMap.put(fieldName, value);
        }

        public Decimal getFiscalYrValue(String fieldName) {
            return this.fieldValueMap.get(fieldName);
        }

        private String getFiscalFieldName(OpportunityLineItem lineItem) {
            String retFieldName;
            Integer currentYear = Date.today().year();
            if(lineItem.Fiscal_Year__c < currentYear) {
                retFieldName = PREVIOUS_YEARS_FIELD_NAME;
            }else{
                retFieldName = 'FY' + String.valueOf(lineItem.Fiscal_Year__c);
            }
            return retFieldName;
        }
        private Decimal getFiscalFieldValue(OpportunityLineItem lineItem) {
            //  Retrieve value from TotalPrice field on OpportunityLineItem
            return lineItem.TotalPrice;
        }

        public Map<String, String> getRowMap() {
            Map<String, String> rowMap = new Map<String, String>();

            rowMap.put('Category', this.rowName);
            rowMap.put('Total', String.valueOf(this.calcRowTotal()));

            for(String fieldName : this.fieldValueMap.keySet()) {
                if(fieldName == TOTAL_FIELD_NAME || fieldName == CATEGORY_FIELD_NAME)continue;
                
                rowMap.put(fieldName, String.valueOf(this.fieldValueMap.get(fieldName)));
            }

            return rowMap;
        }

        private Decimal calcRowTotal() {
            //  Iterate all the map rows to get the total
            Decimal rowTotal = 0;

            for(String fieldName : this.fieldValueMap.keySet()) {
                rowTotal += this.fieldValueMap.get(fieldName);
            }
            return rowTotal;
        }
    }
}
