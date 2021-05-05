/**
 * Created by Tim on 2021-05-05.

 TODO: update to make bilingual
 */

const validateLeadForm = {
  init: (trigger, data) => {
		let errs = [];
		let response = {};

    for( const [k, v] of Object.entries(data)) {
//      console.log('Key/Value ', k + '/' + v);
			const isNull = (v.Value === '') ? true : false;
			const isRequired = v.Required;
			const validationType = v.Validation;
			const validateInline = (trigger === 'onFormSubmit') ? false : true;

			//if the value is not null or the value is null but the field is required, run validation on the value
			if( ( !isNull ) || ( isNull && isRequired ) ){
				console.log('value is not null or is null and required');
				validateLeadForm.validateField(validationType, k, v.Value, isNull)
				.then( result => {
					//field is valid
					if(validateInline){
						// if this is inline validation, jump out of here to a simple inlineResponse method
						console.log('Validation Passed! Return result Inline!');
						console.log(result);
						response = result;
					} else {
						// if this is on submit validation, check to see if the field has been previously added to the fail response, and remove it.
						console.log('Validation Passed! Update Bulk Return Object!');
						const errIndex = errs.indexOf(k);
						console.log('errIndex', errIndex);
						if(errIndex > -1){
							errs.splice(errIndex, 1);
						}
						response = result;
					}
				}).catch( e => {
					// field is not valid
					if(validateInline){
						// if this is inline validation, jump out of here to a simple inlineResponse method
						console.log('Validation Failed! Return result Inline!');
						response = e;
					} else {
						// if this is on submit validation, check to see if the field has been previously added to the fail response, and remove it.
						console.log('Validation Failed! Update Bulk Return Object!');
						console.log('k', k);
						console.log('e.Message', e.Message);
						errs[k] = {
							Message: e.Message
						}
						console.log('errors: ', errs);
						response = {
							Result: 'Fail',
							Errors: errs
						};
					}
				});
			}
  	}
		console.log('after for loop');
  	return new Promise((resolve, reject) => {
  	  console.log('in promise response', response);
			if(response.Result == 'Pass'){
				resolve(response);
			} else {
				reject(response);
			}
		});
  },
  validateField: ( type, name, value, isNull ) => {
		console.log('Validate ' + name + ' with value of "' + value + '" and type of ' + type);
		let response = null;

		if(isNull){
			response = {
				Result: 'Fail',
				Message: name + ' is a required field and cannot be left empty'
			}
		} else {
			if(!(/^[a-zA-ZàâçéèêëîïôûùüÿæœÙÛÜŸÀÂÆÇÉÈÊËÏÎÔŒ  .'-]+$/i.test(value))){
					response = {
						Result: 'Fail',
						Message: name + ' contains invalid characters'
				 }
			} else {
				response = {
					Result: 'Pass'
					}
			}
		}

		return new Promise((resolve, reject) => {
			if(response.Result == 'Pass'){
				resolve(response);
			} else {
				reject(response);
			}
		});
  }
}



export {
	validateLeadForm
}