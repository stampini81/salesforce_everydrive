import { LightningElement, api, wire } from 'lwc';
import getTierImageUrl from '@salesforce/apex/EveryDriveCustomerTierController.getTierImageUrl';
import getAccountName from '@salesforce/apex/EveryDriveCustomerTierController.getAccountName';
import getCustomerTier from '@salesforce/apex/EveryDriveCustomerTierController.getCustomerTier';

export default class EveryDriveCustomerTierBadge extends LightningElement {
    @api recordId;
    imageUrl;
    accountName;
    tierLabel;
    tierClass = '';
    isLoadingImage = false;
    pollHandle;

    @wire(getTierImageUrl, { accountId: '$recordId' })
    wiredImage({ data }) {
        if (data) this.imageUrl = this.withCacheBuster(data);
    }

    connectedCallback() {
        this.refreshTier();
        this.pollHandle = window.setInterval(() => this.refreshTier(), 10000);
    }

    disconnectedCallback() {
        if (this.pollHandle) {
            window.clearInterval(this.pollHandle);
            this.pollHandle = null;
        }
    }

    async refreshTier() {
        if (!this.recordId) {
            return;
        }

        const [tier, name] = await Promise.all([
            getCustomerTier({ accountId: this.recordId }),
            getAccountName({ accountId: this.recordId })
        ]);
        this.accountName = name;
        this.tierLabel = tier || null;
        const normalizedTier = this.normalizeTier(tier);
        this.tierClass = normalizedTier ? `tier-${normalizedTier}` : '';
        await this.fetchImageUrl();
    }

    normalizeTier(tier) {
        if (!tier) {
            return null;
        }
        const normalized = tier.trim().toLowerCase();
        if (normalized === 'bronze') return 'bronze';
        if (normalized === 'prata' || normalized === 'silver') return 'silver';
        if (normalized === 'ouro' || normalized === 'gold') return 'gold';
        return null;
    }

    async fetchImageUrl() {
        if (!this.recordId || this.isLoadingImage) {
            return;
        }
        this.isLoadingImage = true;
        try {
            const url = await getTierImageUrl({ accountId: this.recordId });
            this.imageUrl = url ? this.withCacheBuster(url) : null;
        } finally {
            this.isLoadingImage = false;
        }
    }

    withCacheBuster(url) {
        const sep = url.includes('?') ? '&' : '?';
        return `${url}${sep}v=${Date.now()}`;
    }
}
