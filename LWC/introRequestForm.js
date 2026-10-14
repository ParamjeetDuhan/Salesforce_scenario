import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class IntroRequestForm extends LightningElement {
    @api recordId;

    requesterId;
    targetId;

    get isSubmitDisabled() {
        return !(this.requesterId && this.targetId);
    }

    handleRequesterSelect(event) {
        this.requesterId = event.detail.contactId;
    }

    handleTargetSelect(event) {
        this.targetId = event.detail.contactId;
    }

    handleSubmit() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Introduction request submitted',
                variant: 'success'
            })
        );
        this.template.querySelectorAll('c-contact-picker').forEach((picker) => picker.clear());
        this.requesterId = null;
        this.targetId = null;
    }
}