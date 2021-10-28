/**
 * Created by dave on 2021-10-27.
 */

import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { loadScript } from "lightning/platformResourceLoader";
import Chart from "@salesforce/resourceUrl/ChartJS";
import PERCENT_TODO_FIELD from "@salesforce/schema/System_Issue__c.Percent_To_Do__c";
import PERCENT_INPROGRESS_FIELD from "@salesforce/schema/System_Issue__c.Percent_In_Progress__c";
import PERCENT_DONE_FIELD from "@salesforce/schema/System_Issue__c.Percent_Done__c";

export default class SystemIssuePercentageComplete extends LightningElement {
  @api recordId;
  done = 0;
  todo = 0;
  inProgress = 0;
  chart;
  gauge;
  scriptsLoaded = false;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [PERCENT_DONE_FIELD, PERCENT_INPROGRESS_FIELD, PERCENT_TODO_FIELD]
  })
  wiredSystemIssue(result) {
    if (result.data) {
      this.todo = getFieldValue(result.data, PERCENT_TODO_FIELD);
      this.inProgress = getFieldValue(result.data, PERCENT_INPROGRESS_FIELD);
      this.done = getFieldValue(result.data, PERCENT_DONE_FIELD);
      this.initialize();
    }
    if (result.error) {
      console.log(JSON.parse(JSON.stringify(error)));
    }
  }

  initialize() {
    this.loadScripts().then(() => {
      this.chart ? this.updateChart() : this.initializeChart();
      this.gauge ? this.updateGauge() : this.initializeGauge();
    });
  }

  loadScripts() {
    if (this.scriptsLoaded) {
      return Promise.resolve();
    }
    this.scriptsLoaded = true;
    return loadScript(this, Chart + "/chart.min.js");
  }

  initializeGauge() {
    console.log("init gauge");
    var config = {
      type: "doughnut",
      data: {
        labels: ["Complete"],
        datasets: [
          {
            label: ["Complete"],
            data: [this.done, 100 - this.done],
            backgroundColor: ["#02716B", "#DDDBDA"]
          }
        ]
      },
      options: {
        responsive: false,
        circumference: 270,
        rotation: -135,
        cutout: "65%",
        radius: "100%",
        plugins: {
          legend: {
            position: "bottom"
          },
          title: {
            display: true,
            text: "Overall Progress",
            position: "top",
            align: "center"
          },
          tooltip: {
            enabled: false
          }
        },
        animation: {
          animateScale: true,
          animateRotate: true
        },
        onClick(...args) {
          console.log(args);
        }
      }
    };
    const canvas = this.template.querySelector("canvas.gauge");
    const ctx = canvas.getContext("2d");
    this.gauge = new window.Chart(ctx, config);
  }

  initializeChart() {
    let config = {
      type: "doughnut",
      data: {
        datasets: [
          {
            data: [this.todo, this.inProgress, this.done],
            backgroundColor: ["#C13934", "#FFB75C", "#02716B"],
            label: "Individual Story Statues"
          }
        ],
        labels: ["To Do", "In Progress", "Done"]
      },
      options: {
        responsive: false,
        plugins: {
          legend: {
            position: "bottom"
          },
          tooltip: {
            callbacks: {
              label: function (context) {
                console.log(context);
                return "  " + context.parsed + "%";
              }
            }
          },
          title: {
            display: true,
            text: "Individual Story Statues",
            position: "top",
            align: "center"
          }
        },
        animation: {
          animateScale: true,
          animateRotate: true
        }
      }
    };
    const canvas = this.template.querySelector("canvas.chart");
    const ctx = canvas.getContext("2d");
    this.chart = new window.Chart(ctx, config);
  }

  updateGauge() {
    this.gauge.data.datasets[0].data = [this.done, 100 - this.done];
    this.gauge.update();
  }

  updateChart() {
    this.chart.data.datasets[0].data = [this.todo, this.inProgress, this.done];
    this.chart.update();
  }
}
