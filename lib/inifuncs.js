const ini = require('ini')
const fs = require('fs-extra')
const createDebug = require('debug')

const debug = createDebug('retropie-profiles:lib:inifuncs')

module.exports = {
  get,
  set,
  unset
}

async function get(filename) {
  const data = await fs.readFile(filename, 'utf8')
  const parsed = ini.parse(data)
  return parsed
}

async function set(filename, obj) {
  const data = await fs.readFile(filename, 'utf8')
  const lines = data.split('\n')
  for (const key of Object.keys(obj)) {
    let lineNo = findLineNumber(lines, key)
    if (lineNo === -1) {
      lineNo = lines.length
    }
    const value = obj[key]
    lines[lineNo] = `${key} = ${JSON.stringify(value)}`
    debug('setting line number %o to %o', lineNo, lines[lineNo])
  }
  await fs.writeFile(filename, lines.join('\n'))
}

async function unset(filename, ...names) {
  const data = await fs.readFile(filename, 'utf8')
  const lines = data.split('\n')
  for (const key of names) {
    const lineNo = findLineNumber(lines, key)
    if (lineNo !== -1) {
      const line = lines[lineNo]
      if (!/^ *\#/.test(line)) {
        debug('commenting out line %o for %o', lineNo, key)
        lines[lineNo] = '#' + lines[lineNo]
      } else {
        debug('line %o for %o is already commented out', lineNo, key)
      }
    }
  }
  await fs.writeFile(filename, lines.join('\n'))
}

function findLineNumber(lines, name) {
  for (let i = 0; i < lines.length; i++) {
    const cleaned = lines[i].replace(/^ *\#*/, '')
    const parsed = ini.parse(cleaned)
    if (name in parsed) {
      return i
    }
  }
  return -1
}
