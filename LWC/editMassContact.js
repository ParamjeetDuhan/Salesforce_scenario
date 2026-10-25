import { LightningElement, api, wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContact from '@salesforce/apex/ContactController.getContact';

const COLUMNS = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Email', fieldName: 'Email', type: 'email', editable: true },
    { label: 'Phone', fieldName: 'Phone', type: 'phone', editable: true },
    { label: 'Title', fieldName: 'Title', type: 'text', editable: true }
];

export default class AccountContactsEditor extends LightningElement {
    @api recordId;

    columns = COLUMNS;
    contacts = [];
    error;
    isLoading = true;
    isSaving = false;
    wiredResult;

    draftValues = [];
    errors = {};

    @wire(getContact, { accountId: '$recordId' })
    wiredContacts(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.contacts = data;
            this.error = undefined;
        } else if (error) {
            this.contacts = [];
            this.error = error;
        }
        this.isLoading = false;
    }

    get errorMessage() {
        return this.reduceError(this.error);
    }

    // ---------- handlers ----------
    handleCancel() {
        this.draftValues = [];
        this.errors = {};
    }

    async handleSave(event) {
        const drafts = event.detail.draftValues;

        const validationErrors = this.validate(drafts);
        if (Object.keys(validationErrors.rows).length) {
            this.errors = validationErrors;
            return;
        }
        this.errors = {};

        this.isSaving = true;
        try {
            const settled = await Promise.allSettled(
                drafts.map((draft) => updateRecord({ fields: { ...draft } }))
            );

            const failedDrafts = [];
            const rowErrors = {};
            let savedCount = 0;

            settled.forEach((result, i) => {
                if (result.status === 'fulfilled') {
                    savedCount++;
                } else {
                    const draft = drafts[i];
                    failedDrafts.push(draft);
                    rowErrors[draft.Id] = {
                        title: 'Could not save this row',
                        messages: [this.reduceError(result.reason)],
                        fieldNames: Object.keys(draft).filter((key) => key !== 'Id')
                    };
                }
            });

            this.draftValues = failedDrafts;
            this.errors = { rows: rowErrors, table: {} };

            if (savedCount > 0) {
                await refreshApex(this.wiredResult);
            }

            this.showSummaryToast(savedCount, failedDrafts.length);
        } finally {
            this.isSaving = false;
        }
    }

    // ---------- helpers ----------
    validate(drafts) {
        const rows = {};
        drafts.forEach((draft) => {
            const email = draft.Email;
            if (email && email.trim() && !email.includes('@')) {
                rows[draft.Id] = {
                    title: 'Fix this row before saving',
                    messages: ['Email must contain @'],
                    fieldNames: ['Email']
                };
            }
        });
        return { rows, table: {} };
    }

    showSummaryToast(saved, failed) {
        let title = 'Success';
        let variant = 'success';
        if (failed > 0 && saved > 0) {
            title = 'Partly saved';
            variant = 'warning';
        } else if (failed > 0) {
            title = 'Nothing saved';
            variant = 'error';
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message: `${saved} saved, ${failed} failed`,
                variant
            })
        );
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