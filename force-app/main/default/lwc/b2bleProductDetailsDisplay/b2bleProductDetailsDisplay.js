import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import communityId from '@salesforce/community/Id';
import addToCart from '@salesforce/apex/B2BGetInfo.addAllToCart';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// A fixed entry for the home page.
const homePage = {
    name: 'Home',
    type: 'standard__namedPage',
    attributes: {
        pageName: 'home'
    }
};

/**
 * An organized display of product information.
 *
 * @fires ProductDetailsDisplay#addtocart
 * @fires ProductDetailsDisplay#createandaddtolist
 */
export default class B2bleProductDetailsDisplay extends NavigationMixin(
    LightningElement
) {
    /**
     * An event fired when the user indicates the product should be added to their cart.
     *
     * Properties:
     *   - Bubbles: false
     *   - Composed: false
     *   - Cancelable: false
     *
     * @event ProductDetailsDisplay#addtocart
     * @type {CustomEvent}
     *
     * @property {string} detail.quantity
     *  The number of items to add to cart.
     *
     * @export
     */

    /**
     * An event fired when the user indicates the product should be added to a new wishlist
     *
     * Properties:
     *   - Bubbles: false
     *   - Composed: false
     *   - Cancelable: false
     *
     * @event ProductDetailsDisplay#createandaddtolist
     * @type {CustomEvent}
     *
     * @export
     */

    /**
     * A product image.
     * @typedef {object} Image
     *
     * @property {string} url
     *  The URL of an image.
     *
     * @property {string} alternativeText
     *  The alternative display text of the image.
     */

    /**
     * A product category.
     * @typedef {object} Category
     *
     * @property {string} id
     *  The unique identifier of a category.
     *
     * @property {string} name
     *  The localized display name of a category.
     */

    /**
     * A product price.
     * @typedef {object} Price
     *
     * @property {string} negotiated
     *  The negotiated price of a product.
     *
     * @property {string} currency
     *  The ISO 4217 currency code of the price.
     */

    /**
     * A product field.
     * @typedef {object} CustomField
     *
     * @property {string} name
     *  The name of the custom field.
     *
     * @property {string} value
     *  The value of the custom field.
     */

    /**
     * An iterable Field for display.
     * @typedef {CustomField} IterableField
     *
     * @property {number} id
     *  A unique identifier for the field.
     */

    /**
     * Gets or sets which custom fields should be displayed (if supplied).
     *
     * @type {CustomField[]}
     */
    @api
    customFields;

    /**
     * Gets or sets whether the cart is locked
     *
     * @type {boolean}
     */
    @api
    cartLocked;

    /**
     * Gets or sets the name of the product.
     *
     * @type {string}
     */
    @api
    description;

    /**
     * Gets or sets the product image.
     *
     * @type {Image}
     */
    @api
    image;

    /**
     * Gets or sets whether the product is "in stock."
     *
     * @type {boolean}
     */
    @api
    inStock = false;

    /**
     * Gets or sets the name of the product.
     *
     * @type {string}
     */
    @api
    name;

    /**
     * Gets or sets the price - if known - of the product.
     * If this property is specified as undefined, the price is shown as being unavailable.
     *
     * @type {Price}
     */
    @api
    price;

    /**
     * Gets or sets teh stock keeping unit (or SKU) of the product.
     *
     * @type {string}
     */
    @api
    sku;

    //dspagnuolo: added product id
    @api
    productId;

    _invalidQuantity = false;
    _quantityFieldValue = 1;
    _categoryPath;
    _resolvedCategoryPath = [];

    // A bit of coordination logic so that we can resolve product URLs after the component is connected to the DOM,
    // which the NavigationMixin implicitly requires to function properly.
    _resolveConnected;
    _connected = new Promise((resolve) => {
        this._resolveConnected = resolve;
    });

    connectedCallback() {
        this._resolveConnected();
    }

    disconnectedCallback() {
        this._connected = new Promise((resolve) => {
            this._resolveConnected = resolve;
        });
    }

    /**
     * Gets or sets the ordered hierarchy of categories to which the product belongs, ordered from least to most specific.
     *
     * @type {Category[]}
     */
    @api
    get categoryPath() {
        return this._categoryPath;
    }

    set categoryPath(newPath) {
        this._categoryPath = newPath;
        this.resolveCategoryPath(newPath || []);
    }

    get hasPrice() {
        return ((this.price || {}).negotiated || '').length > 0;
    }

    /**
     * Gets whether add to cart button should be displabled
     *
     * Add to cart button should be disabled if quantity is invalid,
     * if the cart is locked, or if the product is not in stock
     */
    get _isAddToCartDisabled() {
        return this._invalidQuantity || this.cartLocked || !this.inStock;
    }

    handleQuantityChange(event) {
        if (event.target.validity.valid && event.target.value) {
            this._invalidQuantity = false;
            this._quantityFieldValue = event.target.value;

            //dspagnuolo: adding qty to the map
            this.compositeCart[this.recordId] = event.target.value;
        } else {
            this._invalidQuantity = true;
        }
    }

    /**
     * Emits a notification that the user wants to add the item to their cart.
     *
     * @fires ProductDetailsDisplay#addtocart
     * @private
     */
    notifyAddToCart() {
        let quantity = this._quantityFieldValue;
        this.dispatchEvent(
            new CustomEvent('addtocart', {
                detail: {
                    quantity
                }
            })
        );
    }

    /**
     * Emits a notification that the user wants to add the item to a new wishlist.
     *
     * @fires ProductDetailsDisplay#createandaddtolist
     * @private
     */
    notifyCreateAndAddToList() {
        this.dispatchEvent(new CustomEvent('createandaddtolist'));
    }

    /**
     * Updates the breadcrumb path for the product, resolving the categories to URLs for use as breadcrumbs.
     *
     * @param {Category[]} newPath
     *  The new category "path" for the product.
     */
    resolveCategoryPath(newPath) {
        const path = [homePage].concat(
            newPath.map((level) => ({
                name: level.name,
                type: 'standard__recordPage',
                attributes: {
                    actionName: 'view',
                    recordId: level.id
                }
            }))
        );

        this._connected
            .then(() => {
                const levelsResolved = path.map((level) =>
                    this[NavigationMixin.GenerateUrl]({
                        type: level.type,
                        attributes: level.attributes
                    }).then((url) => ({
                        name: level.name,
                        url: url
                    }))
                );

                return Promise.all(levelsResolved);
            })
            .then((levels) => {
                this._resolvedCategoryPath = levels;
            });
    }

    /**
     * Gets the iterable fields.
     *
     * @returns {IterableField[]}
     *  The ordered sequence of fields for display.
     *
     * @private
     */
    get _displayableFields() {
        // Enhance the fields with a synthetic ID for iteration.
        return (this.customFields || []).map((field, index) => ({
            ...field,
            id: index
        }));
    }

    //dspagnuolo: mod for ceragon configuration
    compositeCart = {};

    @track isAddAllToCartDisabled = true;

    handleAntenna2FtChanged(event) {
        console.log("Antenna 2ft changed");
        console.log(event.target.value);
        var productId = "01t09000000lv9AAAQ";
        var qty = event.target.value;
        this.compositeCart[productId] = qty;
        this.runValidation();
    }

    handleAntenna3FtChanged(event) {
        console.log("Antenna 3ft changed");
        console.log(event.target.value);
        var productId = "01t09000000lv9BAAQ";
        var qty = event.target.value;
        this.compositeCart[productId] = qty;
        this.runValidation();
    }

    get softwareOptions() {
        return [
            { label: 'SL - Capacity 1.6G, per carrier - 700€', value: '01t09000000lv9FAAQ' },
            { label: 'SL - Capacity 150M, per carrier - 500€', value: '01t09000000lv9GAAQ' },
            { label: 'SL - Capacity 100M, per carrier - 300€', value: '01t09000000lv9CAAQ' }
        ];
    }

    handleSwChange(event) {
        console.log(event.target.value);
        //remove older selected SW
        if (this.compositeCart.hasOwnProperty("01t09000000lv9FAAQ")) {
            delete this.compositeCart["01t09000000lv9FAAQ"];
        }
        if (this.compositeCart.hasOwnProperty("01t09000000lv9GAAQ")) {
            delete this.compositeCart["01t09000000lv9GAAQ"];
        }
        if (this.compositeCart.hasOwnProperty("01t09000000lv9CAAQ")) {
            delete this.compositeCart["01t09000000lv9CAAQ"];
        }

        this.compositeCart[event.target.value] = "1";
        this.runValidation();
    }

    addAllToCart(event) {
        console.log("adding to cart");
        if (!this.compositeCart.hasOwnProperty(this.recordId)) {
            //this means that the user didn't change main prod qty
            this.compositeCart[this.productId] = "1";
        }
        console.log(this.compositeCart);
        console.log(JSON.stringify(this.compositeCart));

        addToCart({
            communityId: communityId,
            productQtyJSON: JSON.stringify(this.compositeCart),
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
                    messageData: [this.displayableProduct.name],
                    variant: 'error',
                    mode: 'dismissable'
                })
            );
        });
    }

    runValidation() {
        console.log(this.compositeCart);
        var antennaOk = false;
        var swOk = false;
        //check we have at least 2 antennas
        if (this.compositeCart.hasOwnProperty("01t09000000lv9AAAQ") && 
            this.compositeCart.hasOwnProperty("01t09000000lv9BAAQ")) {
                var totalAntennas = parseInt(this.compositeCart["01t09000000lv9AAAQ"]) 
                                    + parseInt(this.compositeCart["01t09000000lv9BAAQ"]);
                console.log("Total antennas: " + totalAntennas);
                if (totalAntennas >= 2) antennaOk = true;
        } else if (this.compositeCart.hasOwnProperty("01t09000000lv9AAAQ")) {
            console.log("1 type antenna");
            var antennaQty = parseInt(this.compositeCart["01t09000000lv9AAAQ"]);
            if (antennaQty >= 2) antennaOk = true;
        } else if (this.compositeCart.hasOwnProperty("01t09000000lv9BAAQ")) {
            console.log("1 type antenna");
            var antennaQty = parseInt(this.compositeCart["01t09000000lv9BAAQ"]);
            if (antennaQty >= 2) antennaOk = true;
        }

        //verify that sw is selected
        if (this.compositeCart.hasOwnProperty("01t09000000lv9FAAQ") ||
            this.compositeCart.hasOwnProperty("01t09000000lv9GAAQ") ||
            this.compositeCart.hasOwnProperty("01t09000000lv9CAAQ")) {
                swOk = true;
        }

        this.isAddAllToCartDisabled = !(antennaOk && swOk);
    }

}