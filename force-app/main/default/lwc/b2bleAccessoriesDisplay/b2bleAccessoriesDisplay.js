import { LightningElement, api } from 'lwc';

export default class B2bleAccessoriesDisplay extends LightningElement {
    @api recordid;
    @api name;
    @api price;
    @api currency;
    @api img;
    @api sku;

    _quantityFieldValue = 1;
    _invalidQuantity = false;

    handleQuantityChange(event) {
        if (event.target.validity.valid && event.target.value) {
            this._invalidQuantity = false;
            this._quantityFieldValue = event.target.value;
        } else {
            this._invalidQuantity = true;
        }
    }

    notifyAddToCart() {
        console.log("Add to cart notify");
        let quantity = this._quantityFieldValue;
        let recordId = this.recordid;
        console.log("record id: " + recordId);
        console.log("quantity: " + quantity);
        this.dispatchEvent(
            new CustomEvent('addtocart', {
                detail: {
                    quantity: this._quantityFieldValue, 
                    recordId: this.recordid
                }
            })
        );
    }
}