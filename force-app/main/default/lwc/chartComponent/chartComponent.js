import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';

// Static Resource
import chartJs from '@salesforce/resourceUrl/chartJS';

// Apex Methods
import getChartData from "@salesforce/apex/chartComponentHandler.getChartData";

export default class GraphLWC extends LightningElement {
    @api recordId;
    @api chartId;

    chart; // Chart Instance
    chartTitle;
    chartProperties; // All of the chart data
    errorMessage;

    async connectedCallback() {

        // Manual Responsiveness
        window.addEventListener(
            "resize",
            this.handleWindowResize
        ); 
        
        // Loading Chart.js library
        await this.loadChartJS();
    
        // Getting Chart Data
        await this.getChartProperties();

        // Initializing Chart
        this.initializeChart();
    }

    disconnectedCallback() {
        
        // Removing listner for Manual Responsiveness
        window.removeEventListener(
            "resize",
            this.handleWindowResize
        );
    }

    /**
     * This method retrieves all necessary data from server required for Chart rendering.
     */
    async getChartProperties() {
        await getChartData({ chartId: this.chartId,
                             recordId: this.recordId })
        .then((result) => {
            result = JSON.parse(result);
            console.log('Response from Server: ', result);
            this.chartTitle = result.chartTitle;
            
            if(result.errorMessage == null) {
                this.chartProperties = result;
            } else {
                this.chartProperties = null;
                this.errorMessage = result.errorMessage;
            }
        })
        .catch((error) => {
          console.log(error);
        });
    }

    initializeChart() {
        if(this.chartProperties != null) {
            
            // Getting canvas from HTML
            const canvas = this.template.querySelector('[data-id="chartCanvas"]');
            const ctx = canvas.getContext('2d');

            // Rendering Chart
            this.chart = new window.Chart(ctx, {
                type: this.chartProperties.chartType, 
                data: {
                    labels: this.chartProperties.labels,

                    // Array of datasets
                    datasets: [{
                        label: this.chartProperties.datasetLabel,
                        data: this.chartProperties.dataset,
                        
                        backgroundColor: this.chartProperties.backgroundColor,
                        borderColor: this.chartProperties.borderColor,
                        borderWidth: this.chartProperties.borderWidth
                    }]
                },
                options: {
                    // if 'true', this option gives 'ResizeObserver' error so manual responsive is
                    // implemented as workaround.
                    responsive: false
                }
            });

            // Manually Resizing the chart as per screen's dimensions
            this.chart.resize();
        }  
    }  

    // ============================
    // ======= UTIL METHODS =======
    // ============================

    async loadChartJS() {
        await loadScript(this, chartJs)
        .then(() => {
            console.log('Chart.js loaded successfully.');
        })
        .catch(error => {
            console.log('ERROR: ', error);
        });
    }

    // Manual Responsiveness
    handleWindowResize = () => {
        if (this.chart != null) {
            this.chart.resize();
        }
    }

}