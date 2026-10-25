import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpenOpportunities from '@salesforce/apex/OpenOpportunitiesController.getOpenOpportunities';

import TASK_OBJECT from '@salesforce/schema/Task';
import SUBJECT_FIELD from '@salesforce/schema/Task.Subject';
import WHAT_ID_FIELD from '@salesforce/schema/Task.WhatId';
import ACTIVITY_DATE_FIELD from '@salesforce/schema/Task.ActivityDate';

const COLUMNS = [
    {
        label: 'Opportunity',
        type: 'button',
        typeAttributes: { label: { fieldName: 'Name' }, name: 'view', variant: 'base' }
    },
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
        typeAttributes: {
            label: 'Create follow-up',
            name: 'followUp',
            disabled: { fieldName: 'isSaving' }
        }
    }
];

const STAGE_OPTIONS = [
    { label: 'All stages', value: 'All' },
    { label: 'Prospecting', value: 'Prospecting' },
    { label: 'Qualification', value: 'Qualification' },
    { label: 'Negotiation', value: 'Negotiation' }
];

export default class OpportunityQuickActions extends NavigationMixin(LightningElement) {
    @api recordId;

    columns = COLUMNS;
    stageOptions = STAGE_OPTIONS;
    selectedStage = 'All';

    opportunities = [];
    error;
    isLoading = true;
    savingIds = [];

    @wire(getOpenOpportunities, { accountId: '$recordId', stage: '$selectedStage' })
    wiredOpportunities({ data, error }) {
        if (data) {
            this.opportunities = data;
            this.error = undefined;
        } else if (error) {
            this.opportunities = [];
            this.error = error;
        }
        this.isLoading = false;
    }

    // ---------- getters ----------
    get rows() {
        return this.opportunities.map((opp) => ({
            ...opp,
            isSaving: this.savingIds.includes(opp.Id)
        }));
    }

    get errorMessage() {
        return this.reduceError(this.error);
    }

    // ---------- handlers ----------
    handleStageChange(event) {
        const newStage = event.detail.value;
        if (newStage !== this.selectedStage) {
            this.isLoading = true;
            this.selectedStage = newStage;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'view') {
            this.openRecord(row.Id);
        } else if (actionName === 'followUp') {
            this.createFollowUp(row);
        }
    }

    handleNewOpportunity() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Opportunity', actionName: 'new' },
            state: {
                defaultFieldValues: encodeDefaultFieldValues({ AccountId: this.recordId })
            }
        });
    }

    // ---------- actions ----------
    openRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId, actionName: 'view' }
        });
    }

    async createFollowUp(row) {
        this.savingIds = [...this.savingIds, row.Id];

        const fields = {};
        fields[SUBJECT_FIELD.fieldApiName] = `Follow up: ${row.Name}`;
        fields[WHAT_ID_FIELD.fieldApiName] = row.Id;
        fields[ACTIVITY_DATE_FIELD.fieldApiName] = this.dateInDays(3);

        try {
            const task = await createRecord({
                apiName: TASK_OBJECT.objectApiName,
                fields
            });
            const url = await this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: { recordId: task.id, actionName: 'view' }
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Follow-up created: {0}',
                    messageData: [{ url, label: 'Open task' }],
                    variant: 'success'
                })
            );
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Could not create follow-up',
                    message: this.reduceError(e),
                    variant: 'error'
                })
            );
        } finally {
            this.savingIds = this.savingIds.filter((id) => id !== row.Id);
        }
    }

    // ---------- helpers ----------
    dateInDays(days) {
        const d = new Date();
        d.setDate(d.getDate() + days);
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return `${d.getFullYear()}-${month}-${day}`;
    }

    reduceError(error) {
        if (!error) {
            return '';
        }
        if (Array.isArray(error.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return error.body?.message || error.message || 'Unknown error';
    }
}