import { readFileSync } from 'node:fs';

const [file, expectedName, expectedType, expectedCreator] = process.argv.slice(2);
if (!file || !expectedName || !expectedType || !expectedCreator) {
  console.error('usage: validate-prc.mjs FILE NAME TYPE CREATOR');
  process.exit(2);
}

const data = readFileSync(file);
if (data.length < 78) throw new Error('PRC is shorter than its database header');

const cString = (start, length) => data.subarray(start, start + length).toString('latin1').split('\0', 1)[0];
const name = cString(0, 32);
const type = data.subarray(60, 64).toString('latin1');
const creator = data.subarray(64, 68).toString('latin1');
const count = data.readUInt16BE(76);

if (name !== expectedName) throw new Error(`database name ${JSON.stringify(name)} != ${JSON.stringify(expectedName)}`);
if (type !== expectedType) throw new Error(`database type ${JSON.stringify(type)} != ${JSON.stringify(expectedType)}`);
if (creator !== expectedCreator) throw new Error(`creator ${JSON.stringify(creator)} != ${JSON.stringify(expectedCreator)}`);
if (data.length < 78 + count * 10) throw new Error('resource table is truncated');

const resources = [];
for (let i = 0; i < count; i += 1) {
  const offset = 78 + i * 10;
  resources.push({
    type: data.subarray(offset, offset + 4).toString('latin1'),
    id: data.readUInt16BE(offset + 4),
    offset: data.readUInt32BE(offset + 6),
  });
}

for (const required of [['code', 1], ['tFRM', 1000], ['tAIB', 1000], ['tSTR', 1000]]) {
  if (!resources.some((resource) => resource.type === required[0] && resource.id === required[1])) {
    throw new Error(`missing resource ${required[0]}:${required[1]}`);
  }
}

for (let i = 0; i < resources.length; i += 1) {
  const end = i + 1 < resources.length ? resources[i + 1].offset : data.length;
  if (resources[i].offset < 78 + count * 10 || resources[i].offset >= end || end > data.length) {
    throw new Error(`invalid resource offset for ${resources[i].type}:${resources[i].id}`);
  }
}

console.log(`Validated ${file}: ${name}, ${type}/${creator}, ${count} resources`);
