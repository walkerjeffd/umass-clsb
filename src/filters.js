/* eslint-disable import/prefer-default-export */

export function number(value) {
  // console.log('filter:number', value);
  return Math.round(value).toLocaleString();
}
