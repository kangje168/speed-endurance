// Optional host-side algorithm check. Not a Monkey C compiler/runtime test.
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

let source = readFileSync(new URL('../source/TrainingEngine.mc', import.meta.url), 'utf8');
const prefix = source.substring(0, source.indexOf('function initialize'));
const fields = [...prefix.matchAll(/\b(?:var|const)\s+(\w+)\s*=/g)].map(m => m[1]);
const methods = [...source.matchAll(/\bfunction\s+(\w+)\s*\(/g)].map(m => m[1]);
source = source.replace('class TrainingEngine {', 'function TrainingEngine() {');
source = source.replace(/static const/g, 'const');
source = source.replace(/\}\s*$/, 'return {' + fields.map(name =>
  `get ${name}(){return ${name};},set ${name}(value){${name}=value;}`
).join(',') + ',' + methods.join(',') + '};}');
source += '\nTrainingEngine.READY=0;TrainingEngine.RUNNING=1;TrainingEngine.RESTING=2;TrainingEngine.FINISHED=3;';

const tests = readFileSync(new URL('../tests/TrainingEngineTest.mc', import.meta.url), 'utf8')
  .replace('using Toybox.Test;', '').replace(/\(:test\)/g, '');
const names = [...tests.matchAll(/function\s+(\w+)\s*\(logger\)/g)].map(m => m[1]);
const evaluate = new Function('Test', source + '\n' + tests + '\nreturn [' +
  names.map(name => `{name:"${name}",pass:${name}(null)}`).join(',') + '];');
const results = evaluate({
  assertEqual: (actual, expected) => assert.equal(actual, expected),
  assert: condition => assert.equal(condition, true)
});
for (const result of results) { assert.equal(result.pass, true); console.log(`PASS ${result.name}`); }
console.log('JavaScript-adapted logic only; Garmin compilation, simulator and hardware remain unverified.');
