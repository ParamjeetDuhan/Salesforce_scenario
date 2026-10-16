import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CURRENCY from '@salesforce/i18n/currency';
import getOpenOpportunities from '@salesforce/apex/OpenOpportunitiesController.getOpenOpportunities';
import closeAsWon from '@salesforce/apex/OpenOpportunitiesController.closeAsWon';

const COLUMNS = [
    { label: 'Opportunity name', fieldName: 'Name', type: 'text' },
    { label: 'Stage', fieldName: 'StageName', type: 'text' },
    { label: 'Amount', fieldName: 'Amount', type: 'currency' },
    {
        label: 'Close date',
        fieldName: 'CloseDate',
        type: 'date',
        typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }
    },
    {
        type: 'button',
        typeAttributes: { label: 'Close as won', name: 'close_won' }
    }
];

const STAGE_OPTIONS = [
    { label: 'All stages', value: 'All' },
    { label: 'Prospecting', value: 'Prospecting' },
    { label: 'Qualification', value: 'Qualification' },
    { label: 'Negotiation', value: 'Negotiation' }
];

export default class OpenOpportunities extends LightningElement {
    @api recordId;

    columns = COLUMNS;
    stageOptions = STAGE_OPTIONS;
    currencyCode = CURRENCY;

    selectedStage = 'All';
    opportunities = [];
    error;
    isLoading = true;
    wiredResult;

    @wire(getOpenOpportunities, { accountId: '$recordId', stage: '$selectedStage' })
    wiredOpportunities(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.opportunities = data;
            this.error = undefined;
        } else if (error) {
            this.opportunities = [];
            this.error = error;
        }
        this.isLoading = false;
    }

    get totalAmount() {
        return this.opportunities.reduce((sum, row) => sum + (row.Amount || 0), 0);
    }

    get errorMessage() {
        return this.reduceError(this.error);
    }

    handleStageChange(event) {
        this.isLoading = true;
        this.selectedStage = event.detail.value;
    }

    async handleRowAction(event) {
        if (event.detail.action.name !== 'close_won') {
            return;
        }
        const opportunityId = event.detail.row.Id;
        this.isLoading = true;
        try {
            await closeAsWon({ opportunityId });
            this.showToast('Success', 'Opportunity closed as won', 'success');
            await refreshApex(this.wiredResult);
        } catch (e) {
            this.showToast('Could not close opportunity', this.reduceError(e), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (!error) {
            return '';
        }
        return error.body?.message || error.message || 'Unknown error';
    }
}