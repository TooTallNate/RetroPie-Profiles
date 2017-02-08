import {Writable} from 'stream'
import React, {Component} from 'react'

export default class WritableBox extends Component {
  constructor(...args) {
    super(...args)
    this.state = { contents: '' }
    this.clear = this.clear.bind(this)

    this.writable = new Writable()
    this.writable.isTTY = true
    this.writable._write = this._write.bind(this)
  }

  _write(buf, encoding, callback) {
    process.nextTick(() => {
      let contents = this.state.contents
      contents += buf.toString('buffer' === encoding ? 'utf8' : encoding)
      this.setState({ contents })
      callback()
    })
  }

  clear() {
    this.setState({ contents: '' })
  }

  render() {
    return <box ref='box' { ...this.props }>{ this.state.contents }</box>
  }
}
