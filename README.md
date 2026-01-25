# Salesforce Chart Composer

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

## 🛠️ Getting Started

### Installation

- The first step is to install the unmanaged package of **Salesforce Chart Composer** from the installation link.  
- Go to **Permission Sets** and search for **Salesforce Chart Composer** permission set and assign it to the desired users.


### Create Sample Records

Before creating a chart, there must be some sample records in the org. For this example, create a set of **Account** records with the standard field `NumberOfEmployees` filled randomly.


### Create a Chart Record

1. Create a new **Chart** object record.  
2. Fill the **Title** field with `Account Employees Count` and leave the **Relationship Field** blank for now.  
3. Click **Save**.  
4. Copy the auto-generated **Chart Id** value.


### Create a Dataset for Chart

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


### Add Dynamic Filters (Optional)

Although the chart is ready to render, you can optionally add extra filters to the dataset:

1. Create a new **Chart Filter** record from the **Filters** related list on the dataset page.
2. Set the following:
   - Field: `NumberOfEmployees`
   - Operator: `Greater Than`
   - Value: `0`

For best practices, name your filters as numbers (e.g. `1`, `2`, etc.).


### Add Chart Component

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
### Chart Dataset
### Chart Filter

---

To report any bugs, use **Issues** tab of this repository. Similarly, use **Discussions** to suggest or discuss anything related to the app.

