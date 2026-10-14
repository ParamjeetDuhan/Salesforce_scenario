import { LightningElement, api } from 'lwc';
import searchContacts from '@salesforce/apex/ContactPickerController.searchContacts';

const DEBOUNCE_MS = 300;
const MIN_CHARS = 2;

export default class ContactPicker extends LightningElement {
    @api label;
    @api accountId;
    @api excludeId;

    contacts = [];
    selectedContact;
    isLoading = false;
    hasSearched = false;
    error;

    delayTimeout;
    latestRequest = 0;

    get visibleContacts() {
        return this.contacts.filter((c) => c.Id !== this.excludeId);
    }

    get hasResults() {
        return this.visibleContacts.length > 0;
    }

    get showNoResults() {
        return this.hasSearched && !this.isLoading && !this.hasResults;
    }

    get errorMessage() {
        return this.error?.body?.message || 'Could not load contacts.';
    }

    handleInput(event) {
        const term = event.target.value.trim();
        clearTimeout(this.delayTimeout);

        if (term.length < MIN_CHARS) {
            this.contacts = [];
            this.hasSearched = false;
            this.error = undefined;
            return;
        }
        this.delayTimeout = setTimeout(() => this.search(term), DEBOUNCE_MS);
    }

    async search(term) {
        const requestId = ++this.latestRequest;
        this.isLoading = true;
        this.error = undefined;
        try {
            const result = await searchContacts({
                accountId: this.accountId,
                searchTerm: term,
                excludeId: this.excludeId
            });
            if (requestId !== this.latestRequest) return;
            this.contacts = result;
        } catch (e) {
            if (requestId !== this.latestRequest) return;
            this.error = e;
            this.contacts = [];
        } finally {
            if (requestId === this.latestRequest) {
                this.isLoading = false;
                this.hasSearched = true;
            }
        }
    }

    handleSelect(event) {
        const contactId = event.currentTarget.dataset.id;
        this.selectedContact = this.contacts.find((c) => c.Id === contactId);
        this.contacts = [];
        this.hasSearched = false;
        this.fireSelect(this.selectedContact.Id, this.selectedContact.Name);
    }

    handleClear() {
        this.resetState();
        this.fireSelect(null, null);
    }

    @api
    clear() {
        this.resetState();
    }

    resetState() {
        clearTimeout(this.delayTimeout);
        this.latestRequest++;
        this.selectedContact = undefined;
        this.contacts = [];
        this.hasSearched = false;
        this.isLoading = false;
        this.error = undefined;
    }

    fireSelect(contactId, contactName) {
        this.dispatchEvent(
            new CustomEvent('contactselect', { detail: { contactId, contactName } })
        );
    }

    disconnectedCallback() {
        clearTimeout(this.delayTimeout);
    }
}