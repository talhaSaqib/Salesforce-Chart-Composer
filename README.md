# Salesforce Chart Composer: Getting Started

Salesforce Chart Composer is an unmanaged package to create various kinds of charts using Salesforce records. The product is suitable for both developers and admins as it utilizes the standard Salesforce user interface to create **Chart** records while also giving the option to write Custom SOQL. The charts produced through Salesforce Chart Composer can be placed on Apps, Record Pages, and Homepages.

| Latest Version | 1.1 |
| ------------- | ------------- |
| Installation Link  | [Package](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2w000009RhYY) |

---

## 📌 Table of Contents

- [Installation](#installation)  
- [Create Sample Records](#create-sample-records)  
- [Create a Chart Record](#create-a-chart-record)  
- [Create a Dataset for Chart](#create-a-dataset-for-chart)  
- [Add Dynamic Filters (Optional)](#add-dynamic-filters-optional)  
- [Add Chart Component](#add-chart-component)  
- [Object References](#object-references)

---

## Installation

- The first step is to install the unmanaged package of **Salesforce Chart Composer** from the installation link.  
- Go to **Permission Sets** and search for **Salesforce Chart Composer** permission set and assign it to the desired users.


## Create Sample Records

Before creating a chart, there must be some sample records in the org. For this example, create a set of **Account** records with the standard field `NumberOfEmployees` filled randomly.


## Create a Chart Record

1. Create a new **Chart** object record.  
2. Fill the **Title** field with `Account Employees Count` and leave the **Relationship Field** blank for now.  
3. Click **Save**.  
4. Copy the auto-generated **Chart Id** value.


## Create a Dataset for Chart

On the Chart record, create a new **Chart Dataset** object record from the related list and fill in the following:

| Field             | Value                  |
|------------------|------------------------|
| Dataset Label    | Number of Employees    |
| Chart Type       | Bar                    |
| Source Object    | Account                |
| Source Field     | NumberOfEmployees      |
| Source Label     | Name                   |
| Records Limit    | 50                     |
| Sort By          | NumberOfEmployees      |
| Sort Order       | Ascending              |
| Border Color     | black                  |
| Border Width     | 1                      |
| Background Color | pink                   |

Leave all other fields as default and click **Save**.

> You can also create multiple datasets for the same chart, but this example uses only one.


## Add Dynamic Filters (Optional)

Although the chart is ready to render, you can optionally add extra filters to the dataset:

1. Create a new **Chart Filter** record from the **Filters** related list on the dataset page.
2. Set the following:
   - Field: `NumberOfEmployees`
   - Operator: `Greater Than`
   - Value: `0`

For best practices, name your filters as numbers (e.g. `1`, `2`, etc.).


## Add Chart Component

Finally, add the chart to a page:

1. Click the **Gear** icon at the top right.  
2. Click **Edit Page** to open **Lightning App Builder**.  
3. From the custom components, select `chartComponent` and drag it to the page.  
4. Paste the copied **Chart Id** into the Chart Id field.  
5. Click **Save**. 

You should now see the chart rendered on the Lightning page.

---

## 📚 Object References

### Chart  
- **Object Name:** Chart  
- **API Name:** `Chart__c`  
- This object is used to store metadata about a chart that can be rendered using the `chartComponent` in Lightning App Builder.


#### Fields

| **Label**             | **API Name**               | **Type**       | **Description** |
|-----------------------|----------------------------|----------------|-----------------|
| **Title**             | `Name`                     | Text           | The title of the chart that will be displayed on the chart component. |
| **Chart Id**          | `Chart_Id__c`              | Auto Number    | The unique identifier used to render the chart via the Lightning component. |
| **Relationship Field**| `Relationship_Field__c`    | Text           | (Optional) API name of a lookup field to make the chart dynamically related to a record. For example, if the dataset source object is `Opportunity`, and this field contains `AccountId`, then when the chart is placed on an Account record page, it will filter the data for that account. |

---

### Chart Filter
- **Object Name:** Chart Filter  
- **API Name:** `Chart_Filter__c`  
- Represents a filter condition applied to a chart dataset in Salesforce Chart Composer. Filters restrict which records are used in a chart based on field criteria.

#### Fields

 **Label**           | **API Name**            | **Type**        | **Description**                                                                                                                                                       |
|---------------------|-------------------------|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Name**            | `Name`                  | Text            | The name of the Chart Filter record. For best practices, name your filters as numbers (e.g., 1, 2, etc.). Use this field to identify a filter in the Custom Filters Logic field of the related Dataset. |
| **Field**           | `Field__c`              | Text            | This should contain the API name of a field present in the related Dataset’s Source Object. For example, if the related Dataset has `Account` as Source Object, then this can contain any API field name of Account. |
| **Operator**        | `Operator__c`           | Picklist        | A list of comparison operators to choose from: <br>• Equals – All <br>• Not Equals – All <br>• Less Than – Number <br>• Lesser or Equal – Number <br>• Greater Than – Number <br>• Greater or Equal – Number <br>• Contains – Text <br>• Does Not Contain – Text |
| **Value**           | `Value__c`              | Text            | The value for the respective field. Text values must be enclosed with single quotes (`'`). Decimal numbers must use a dot (`.`) as the decimal point. <br> Date Format: `YYYY-MM-DD` <br> DateTime Format: `YYYY-MM-DDThh:mm:ssZ` |
| **Dataset**         | `Dataset__c`            | Master-Detail   | The lookup to the Chart Dataset object. It represents the relationship between a dataset and a filter. |
| **Source Object**   | `Source_Object__c`      | Formula (Hidden) | The value of the Source Object field in the related Dataset. |

---

### Chart Dataset
- **Object Name:** Chart Dataset  
- **API Name:** `Chart_Dataset__c`  
- A dataset defines the data source, chart type, filters, sorting, and visual styling for a chart in Salesforce Chart Composer.

#### Fields

| **Label**                | **API Name**                 | **Type**        | **Description** |
|--------------------------|------------------------------|-----------------|-----------------|
| **Dataset Name**         | `Name`                       | Auto Number     | The name of the dataset record. |
| **Dataset Label**        | `Dataset_Label__c`           | Text            | The label of the dataset that will be shown in the chart component. |
| **Chart**                | `Chart__c`                   | Master-Detail   | Lookup to the Chart object. It represents the relationship between a chart and a dataset. |
| **Chart Type**           | `Chart_Type__c`              | Picklist        | The type of chart to render (e.g., Pie, Bar, Line, etc.). |
| **Use Custom SOQL**      | `Use_Custom_SOQL__c`         | Checkbox        | If checked, the user can provide a custom SOQL query for the dataset. When used, fields from Source Object, Filters, and Styling sections are ignored. |
| **Source Object**        | `Source_Object__c`           | Text            | The API name of the sObject whose records will be shown in the chart. |
| **Source Field**         | `Source_Field__c`            | Text            | The API name of the field whose values will be displayed in the chart (used as values). Supported types: Integer, Currency, Double, Long, Percent. |
| **Source Label**         | `Source_Label__c`            | Text            | The API name of the field whose values will be used as labels on the chart. Supported types: String, Picklist, Integer, Double, Email, Date, ID. |
| **Earliest Date**        | `Earliest_Date__c`           | Date            | Only records with CreatedDate greater than or equal to this value will be included. |
| **Latest Date**          | `Latest_Date__c`             | Date            | Only records with CreatedDate less than or equal to this value will be included. |
| **Records Limit**        | `Records_Limit__c`           | Number          | Limits how many records are included in the chart. Value must be between 0 and 50,000. |
| **Filter Requirements**  | `Filter_Requirements__c`     | Picklist        | Determines how related Chart Filter records should be evaluated (e.g., all must be true, any must be true, custom logic). |
| **Custom Filters Logic** | `Custom_Filters_Logic__c`    | Text Area       | Logical expression controlling how related filters apply (example: `1 AND 2 OR (3 AND 4)`). Only used if Filter Requirements are set to Custom. |
| **Sort By**              | `Sort_By__c`                 | Text            | API name of the field by which the dataset records should be sorted. |
| **Sort Order**           | `Sort_Order__c`              | Picklist        | Sort order: Ascending or Descending. |
| **Border Color**         | `Border_Color__c`            | Text            | The color of the border for dataset visuals. Can be hex, RGB, or named color. |
| **Border Width**         | `Border_Width__c`            | Number          | Thickness of the border for dataset visuals. |
| **Background Color**     | `Background_Color__c`        | Text            | Background color for dataset visuals (hex, RGB, or named). |

---

To report any bugs, use **Issues** tab of this repository. Similarly, use **Discussions** to suggest or discuss anything related to the app.

