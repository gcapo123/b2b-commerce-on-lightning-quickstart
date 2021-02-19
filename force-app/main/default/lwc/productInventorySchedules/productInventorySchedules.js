import { LightningElement, api, wire, track } from 'lwc';
import getProductInventorySchedules from '@salesforce/apex/ProductInventoryScheduleController.getProductInventorySchedules';
import registerNotify from '@salesforce/apex/ProductInventoryScheduleController.registerNotify';
import getUserEmail from '@salesforce/apex/ProductInventoryScheduleController.getUserEmail';
import Id from '@salesforce/user/Id';

export default class ProductInventorySchedules extends LightningElement {
    @api recordId;
    @api flexipageRegionWidth;
    @api inventorySchedules;
    @api showInventoryMessage = false;
    //TODO: check if the user is already registered and in that case show a un register button
    @api showNotifyButton = false;
    userId = Id;
    @api userEmail;

    @track isModalOpen = false;

    @wire (getProductInventorySchedules, {productId: '$recordId'})
        productInventorySchedules({error, data}) {
            if (error) {
                console.log("Error on product inventory schedules");
                console.log(error);
            } else if (data) {
                console.log("Got product inventory schedules");
                console.log("Product Id " + this.recordId);
                console.log(data);
                var tmpSchedules = [];
                for (var i=0; i<data.length; i++) {
                    /**
                     * Since spring 20 object returned by apex classes are immutable objects so we need
                     * to do this trick in order to add additional properties to the object
                     */
                    var is = JSON.parse(JSON.stringify(data[i]));
                    if (i==0 && is.Quantity_Available__c > 0) {
                        is.orderStatus = "Available";
                    } else if (i>0 && is.Quantity_Available__c > 0 && is.Available_For_Preorder__c) {
                        is.orderStatus = "Pre-Order";
                    } else {
                        if (i==0 && is.Quantity_Available__c == 0) {
                            this.showInventoryMessage = true;
                            this.showNotifyButton = true;
                        }
                        is.orderStatus = "Not Orderable";
                    }

                    tmpSchedules.push(is);
                }
                this.inventorySchedules = tmpSchedules;
                
            }
        }

    @wire (getUserEmail, {userId: "$userId"})
        getUserEmailResult({error, data}) {
            if (error) {
                console.log("Error retrieving user email");
                console.log(error);
            } else if (data) {
                console.log("user email: " + data);
                this.userEmail = data;
            }
        }

    notifyRegistration() {
        registerNotify({productId: this.recordId, userId: this.userId})
            .then(result => {
                if (result) {
                    console.log("Notify inserted")
                    this.isModalOpen = true;
                } 
            })
            .catch(error => {
                console.log("Exception inserting notify");
                console.log(error);
                alert("Something went wrong, retry later");
            })

        
        //TODO: add spinner
    }

    closeModal() {
        this.isModalOpen = false;
    }
}