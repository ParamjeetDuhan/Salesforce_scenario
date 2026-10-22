import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ID_FIELD from '@salesforce/schema/Account.Id';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import RATING_FIELD from '@salesforce/schema/Account.Rating';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';

const FIELDS = [NAME_FIELD, RATING_FIELD, PHONE_FIELD, INDUSTRY_FIELD];

export default class AccountQuickUpdate extends LightningElement {
    @api recordId;

    record;
    error;
    isLoading = true;

    isEditMode = false;
    isSaving = false;
    draftRating;
    draftPhone;

    ratingOptions = [];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ data, error }) {
        if (data) {
            this.record = data;
            this.error = undefined;
        } else if (error) {
            this.record = undefined;
            this.error = error;
        }
        this.isLoading = false;
    }

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: RATING_FIELD
    })
    wiredRatingValues({ data }) {
        if (data) {
            this.ratingOptions = data.values;
        }
    }

    // ---------- read-mode getters ----------
    get name() {
        return getFieldValue(this.record, NAME_FIELD);
    }
    get rating() {
        return getFieldValue(this.record, RATING_FIELD);
    }
    get phone() {
        return getFieldValue(this.record, PHONE_FIELD);
    }
    get industry() {
        return getFieldValue(this.record, INDUSTRY_FIELD);
    }
    get ratingBadgeClass() {
        if (this.rating === 'Hot') {
            return 'slds-theme_warning';
        }
        if (this.rating === 'Cold') {
            return 'slds-badge_lightest';
        }
        return '';
    }
    get errorMessage() {
        return this.reduceError(this.error);
    }

    // ---------- handlers ----------
    handleEdit() {
        this.draftRating = this.rating;
        this.draftPhone = this.phone;
        this.isEditMode = true;
    }

    handleCancel() {
        this.isEditMode = false;
    }

    handleRatingChange(event) {
        this.draftRating = event.detail.value;
        this.clearPhoneError();
    }

    handlePhoneChange(event) {
        this.draftPhone = event.target.value;
        this.clearPhoneError();
    }

    async handleSave() {
        if (!this.validate()) {
            return;
        }
        this.isSaving = true;
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[RATING_FIELD.fieldApiName] = this.draftRating;
        fields[PHONE_FIELD.fieldApiName] = this.draftPhone?.trim() || null;

        try {
            await updateRecord({ fields });
            this.showToast('Success', 'Account updated', 'success');
            this.isEditMode = false;
        } catch (e) {
            this.showToast('Could not save', this.reduceError(e), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    // ---------- helpers ----------
    validate() {
        const phoneInput = this.template.querySelector('[data-id="phone"]');
        const phoneEmpty = !this.draftPhone || !this.draftPhone.trim();
        if (this.draftRating === 'Hot' && phoneEmpty) {
            phoneInput.setCustomValidity('Phone is required when Rating is Hot');
        } else {
            phoneInput.setCustomValidity('');
        }
        return phoneInput.reportValidity();
    }

    clearPhoneError() {
        const phoneInput = this.template.querySelector('[data-id="phone"]');
        if (phoneInput) {
            phoneInput.setCustomValidity('');
            phoneInput.reportValidity();
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
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