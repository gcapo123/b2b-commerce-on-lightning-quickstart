import { LightningElement, api, wire } from 'lwc';

import getProductSpareParts from '@salesforce/apex/B2BLEAccessoriesController.getProductSpareParts';
import communityId from '@salesforce/community/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import addToCart from '@salesforce/apex/B2BLEAccessoriesController.addToCart';

export default class B2bleAccessories extends LightningElement {
    @api recordId;
    @api effectiveAccountId;

    /**
     * Gets the normalized effective account of the user.
     *
     * @type {string}
     * @readonly
     * @private
     */
    get resolvedEffectiveAccountId() {
        const effectiveAccountId = this.effectiveAccountId || '';
        let resolved = null;

        if (
            effectiveAccountId.length > 0 &&
            effectiveAccountId !== '000000000000000'
        ) {
            resolved = effectiveAccountId;
        }
        return resolved;
    }

    @wire(getProductSpareParts, {
        communityId: communityId,
        productId: '$recordId',
        effectiveAccountId: '$resolvedEffectiveAccountId'
    })
    products;

    addToCart(event) {
        console.log("recordi id: " + event.detail.recordId);
        console.log("quantity: " + event.detail.quantity);
        addToCart({
            communityId: communityId,
            productId: event.detail.recordId,
            quantity: event.detail.quantity,
            effectiveAccountId: this.resolvedEffectiveAccountId
        })
            .then(() => {
                this.dispatchEvent(
                    new CustomEvent('cartchanged', {
                        bubbles: true,
                        composed: true
                    })
                );
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Your cart has been updated.',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            })
            .catch(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message:
                            '{0} could not be added to your cart at this time. Please try again later.',
                        messageData: [event.detail.recordId],
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            });
    }
}