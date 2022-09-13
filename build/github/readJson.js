#!/usr/bin/env node

let fs=require('fs');
let rawData = fs.readFileSync('result.json');
let result = JSON.parse(rawData);

const response = {
  status: result.result.status,
  isDone: result.result.done,
  isSuccess: result.result.success,
  numOfComponents: result.result.numberComponentsTotal + result.result.numberTestsTotal,
  numOfComponentsDeployed: result.result.numberComponentsDeployed + result.result.numberTestsCompleted
}
process.stdout.write( JSON.stringify(response) )
