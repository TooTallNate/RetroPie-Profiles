import {Console} from 'console'
import {Writable} from 'stream'
import React, {Component} from 'react'

export default class Logger extends Component {
  constructor(...args) {
    super(...args)
    const contents = ''
    this.state = { contents }
    this.clear = this.clear.bind(this)

    this.writable = new Writable()
    this.writable._write = this._write.bind(this)

    this.console = new Console(this.writable)
    this.log = this.console.log
  }

  componentDidMount() {
    this.log('This is the Logger!')
    Object.defineProperty(global, 'console', { value: this.console })
  }

  componentDidUpdate() {
    // force to bottom
    this.refs.scrollable.setScrollPerc(100)
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
    return (
      <box
        draggable={true}
        width={40}
        height={15}
        label='Logger'
        top={0}
        right={0}
        border={{
          type: 'line'
        }}
      >
        <button left={5} style={{ bg: 'green', fg: 'black' }} shrink={true} onPress={ this.clear }
          keys={true}
          vi={true}
          mouse={true}
        >[ Clear ]</button>
        <line top={1} orientation='horizontal' width='100%-2' />
        <box
          ref='scrollable'
          top={2}
          style={{
            fg: 'white',
            border: {
              fg: 'red',
              bold: true
            }
          }}
          scrollable={true}
          alwaysScroll={true}
          keys={true}
          vi={true}
          mouse={true}
          { ...this.props }
        >
          { this.state.contents }
        </box>
      </box>
    )
  }
}

