/**
 * Created by Tim on 2021-04-26.
 */

import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import initMethod from '@salesforce/apex/FactoryStore_MCWrapperController.initMethod';

export default class FactoryStoreCmsContentPost extends LightningElement {

  @track contentKey;
  @track post = '';

  @track postTitle;

  @wire(CurrentPageReference) currentPageReference;

  get recordIdFromState(){
    let fullKey = (this.currentPageReference.attributes.contentKey) ? this.currentPageReference.attributes.contentKey : this.currentPageReference.attributes.urlAlias;

    const regex = /-MC[A-Z0-9]+$/;
    let keySegment = fullKey.match(regex);
    let isoKey = keySegment[0].replace('-', '');
		this.contentKey = isoKey;

		if(isoKey !== ''){
			const result = initMethod({ contentKey: isoKey })
					.then( (result) => {
						this.post = result[0];
						this.renderPost();
     			}).catch(e => {
							console.log('error: ', e);
					});
		} else {
			console.log('contentkey not set');
		}
  }

	renderedCallback(){
		if(this.contentKey === undefined){
			this.recordIdFromState;
 	 	}
 	}

 	renderPost(){
 	  const post = this.post;
 	  console.log('readable post: ', JSON.parse( JSON.stringify( post ) ) );
 	  this.postTitle = post.title;
  }
}