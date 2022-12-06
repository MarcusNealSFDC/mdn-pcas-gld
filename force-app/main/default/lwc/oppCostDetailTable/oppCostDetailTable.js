import { LightningElement, wire, track, api } from "lwc";
import getOppDetail from "@salesforce/apex/PNNL_OppCostDetailTableController.getOppDetail";

export default class DatatableExample extends LightningElement {
  @api recordId;
  @track columns;
  @track data = [];
  @track error;

  @wire(getOppDetail, { oppId: "$recordId" })
  wiredoppdetail({ error, data }) {
    if (data) {
      this.columns = data.columns;
      this.data = data.recs;
    } else if (error) {
      console.log("error:" + error);
      this.error = error;
    }
  }
}
