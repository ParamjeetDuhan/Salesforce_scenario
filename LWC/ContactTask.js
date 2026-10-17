import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTasks from '@salesforce/apex/TaskHandler.getTasks';
import markComplete from '@salesforce/apex/TaskHandler.markComplete';

const DEBOUNCE_MS = 300;
const MIN_CHARS = 2;

const PRIORITY_OPTIONS = [
    { label: 'All', value: 'All' },
    { label: 'High', value: 'High' },
    { label: 'Normal', value: 'Normal' },
    { label: 'Low', value: 'Low' }
];

export default class ContactTasks extends LightningElement {
    @api recordId;

    priorityOptions = PRIORITY_OPTIONS;
    selectedPriority = 'All';
    searchKey = '';

    tasks = [];
    error;
    isLoading = true;
    wiredResult;
    delayTimeout;

    @wire(getTasks, {
        contactId: '$recordId',
        priority: '$selectedPriority',
        searchTerm: '$searchKey'
    })
    wiredTasks(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.tasks = data;
            this.error = undefined;
        } else if (error) {
            this.tasks = [];
            this.error = error;
        }
        this.isLoading = false;
    }

    get errorMessage() {
        return this.reduceError(this.error);
    }

    handleSearchChange(event) {
        const term = event.target.value.trim();
        clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            const newKey = term.length >= MIN_CHARS ? term : '';
            if (newKey !== this.searchKey) {
                this.isLoading = true;
                this.searchKey = newKey;
            }
        }, DEBOUNCE_MS);
    }

    handlePriorityChange(event) {
        const newPriority = event.detail.value;
        if (newPriority !== this.selectedPriority) {
            this.isLoading = true;
            this.selectedPriority = newPriority;
        }
    }

    async handleMarkComplete(event) {
        const taskId = event.currentTarget.dataset.id;
        this.isLoading = true;
        try {
            await markComplete({ taskId });
            this.showToast('Success', 'Task marked as complete', 'success');
            await refreshApex(this.wiredResult);
        } catch (e) {
            this.showToast('Could not complete task', this.reduceError(e), 'error');
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

    disconnectedCallback() {
        clearTimeout(this.delayTimeout);
    }
}