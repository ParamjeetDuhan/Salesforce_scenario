import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import LMS components for subscribing
import { publish, subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import CASE_CHANNEL from '@salesforce/messageChannel/caseChannel__c';

export default class CaseDetails extends LightningElement {
    selectedCaseId;
    subscription = null;

    @wire(MessageContext)
    messageContext;

    // Component lifecycle hook to kickstart listening
    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                CASE_CHANNEL,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    handleMessage(message) {
        // Extract the caseId from the incoming payload
        this.selectedCaseId = message.caseId;
    }

    handleSuccess() {

            publish(this.messageContext, CASE_CHANNEL, {
        caseId: event.detail.id,
        action: 'UPDATED'
    });
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Case updated successfully via LDS!',
                variant: 'success'
            })
        );
    }
       disconnectedCallback() {
       unsubscribe(this.subscription);
       this.subscription = null;
   }
}
