import { LightningElement, api, wire, track } from 'lwc';
import getRelatedCases from '@salesforce/apex/CaseTableController.getRelatedCases';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { label: 'Case Number', fieldName: 'CaseNumber', type: 'text' },
    { label: 'Subject', fieldName: 'Subject', type: 'text' },
    { label: 'Status', fieldName: 'Status', type: 'text' },
    { label: 'Priority', fieldName: 'Priority', type: 'text' },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date', 
        typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' } 
    }
];

import { publish, MessageContext } from 'lightning/messageService';
import CASE_CHANNEL from '@salesforce/messageChannel/caseChannel__c';

export default class CaseConsole extends LightningElement {
    @api recordId; 
    columns = COLUMNS;
    caseData = [];
    errors;
    wiredResult;
    subscription = null;

    selectedStatus = 'All'; 

    get statusOptions() {
        return [
            { label: 'All Statuses', value: 'All' },
            { label: 'New', value: 'New' },
            { label: 'Working', value: 'Working' },
            { label: 'Escalated', value: 'Escalated' },
            { label: 'Closed', value: 'Closed' }
        ];
    }
     
    connectedCallback() {
        if(!this.subscription){
                this.subscription = subscribe(
        this.messageContext, CASE_CHANNEL,
        (msg) => this.handleMessage(msg),
        { scope: APPLICATION_SCOPE }
    );
        }
}

    // Reactive wire service updates every time '$recordId' or '$selectedStatus' changes
    @wire(getRelatedCases, { accountId: '$recordId', statusFilter: '$selectedStatus' })
    wiredCases({ result }) {
        this.wiredResult = result;          // keep the whole result, not just {data, error}
    const { data, error } = result;
        if (data) {
            this.caseData = data;
            this.errors = undefined;
        } else if (error) {
            this.errors = error;
            this.caseData = [];
        }
    }

    // Captures the combobox change event and updates the reactive property
    handleStatusChange(event) {
        this.selectedStatus = event.target.value;
    }

        @wire(MessageContext)
    messageContext;

     handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            const selectedCaseId = selectedRows[0].Id;
            
            // Broadcast the Case ID via LMS
            const payload = { caseId: selectedCaseId };
            publish(this.messageContext, CASE_CHANNEL, payload);
        }
    }

    disconnectedCallback() {
    unsubscribe(this.subscription);
    this.subscription = null;
}

handleMessage(msg) {
    if (msg.action === 'UPDATED') {
        refreshApex(this.wiredResult);
    }
}
}
