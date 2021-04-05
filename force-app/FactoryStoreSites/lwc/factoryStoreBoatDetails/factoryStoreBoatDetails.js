/**
 * Created by Tim on 2021-04-05.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';


export default class FactoryStoreBoatDetails extends NavigationMixin(LightningElement) {
  @api boat;
}