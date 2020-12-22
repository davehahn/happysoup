/**
 * Created by dave on 2020-02-27.
 */

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const gen8DigitId = () => {
  return Math.random().toString(36).substring(2, 10);
}

const errorToast = ( cmp, msg, title ) =>
{
  title = typeof( title ) === 'undefined' ?
      'An Error Occurred' : title;
  showToast( cmp, 'error', msg, title );
}

const warningToast = ( cmp, msg, title ) =>
{
  title = typeof( title ) === 'undefined' ?
      'Warning!' : title;
  showToast( cmp, 'warning', msg, title );
}

const successToast = ( cmp, msg, title ) =>
{
  title = typeof( title ) === 'undefined' ?
    'Success!' : title;
  showToast( cmp, 'success', msg, title );
}

const infoToast = ( cmp, msg, title ) =>
{
  console.log( 'info toast' );
  title = typeof( title ) === 'undefined' ?
    'Application Information' : title;
  showToast( cmp, 'info', msg, title );
}

const showToast = ( cmp, variant, message, title ) =>
{
  const evt = new ShowToastEvent({
    title: title,
    message: message,
    variant: variant,
    mode: 'dismissable'
  });
  cmp.dispatchEvent(evt);
}

const reduceErrors = (errors) => {
  if (!Array.isArray(errors)) {
    errors = [errors];
  }

  return (
    errors
      // Remove null/undefined items
      .filter((error) => !!error)
      // Extract an error message
      .map((error) => {
          // UI API read errors
          if (Array.isArray(error.body)) {
              return error.body.map((e) => e.message);
          }
          // UI API DML, Apex and network errors
          else if (error.body && typeof error.body.message === 'string') {
              return error.body.message;
          }
          // JS errors
          else if (typeof error.message === 'string') {
              return error.message;
          }
          // Unknown error shape so try HTTP status text
          return error.statusText;
      })
      // Flatten
      .reduce((prev, curr) => prev.concat(curr), [])
      // Remove empty strings
      .filter((message) => !!message)
  );
}

export {
  gen8DigitId,
  errorToast,
  warningToast,
  successToast,
  infoToast,
  reduceErrors
}