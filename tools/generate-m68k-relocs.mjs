import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';

const [elf, output, readelf = 'm68k-none-elf-readelf'] = process.argv.slice(2);
if (!elf || !output) {
  console.error('usage: generate-m68k-relocs.mjs ELF OUTPUT [READELF]');
  process.exit(2);
}

const text = execFileSync(readelf, ['-rW', elf], { encoding: 'utf8' });
let inTextRelocations = false;
const offsets = [];

for (const line of text.split('\n')) {
  const section = line.match(/^Relocation section '([^']+)'/);
  if (section) {
    inTextRelocations = section[1] === '.rela.text' || section[1] === '.rel.text';
    continue;
  }
  if (!inTextRelocations || !line.includes('R_68K_32')) continue;
  const match = line.trim().match(/^([0-9a-fA-F]+)/);
  if (!match) continue;
  const offset = Number.parseInt(match[1], 16) - 0x10000000;
  if (offset < 0 || offset > 0x3ffff) {
    throw new Error(`relocation outside code0001: ${line.trim()}`);
  }
  offsets.push(offset);
}

const unique = [...new Set(offsets)].sort((a, b) => a - b);
const body = unique.map((offset) => `\t.long 0x${offset.toString(16).padStart(8, '0')}`).join('\n');
writeFileSync(output,
  `.section .reloc_offsets,"a"\n${body}\n`);
console.log(`Generated ${unique.length} Palm runtime relocations`);
