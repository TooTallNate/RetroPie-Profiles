#!/usr/bin/env node
import {inspect} from 'util'
import pkg from '../package.json'

// XXX: this import order is important…
// DO NOT re-arrange or else react-blessed breaks :/
import React, {Component, Children} from 'react'
import blessed from 'blessed'
import {render} from 'react-blessed'

import Logger from '../logger'
//import Image from '../image'
import WritableBox from '../writable-box'

class App extends Component {
  constructor(...args) {
    super(...args)
    this.onResize = this.onResize.bind(this)
  }

  componentDidMount() {
    screen.on('resize', this.onResize)
  }

  componentWillUnmount() {
    screen.removeListener('resize', this.onResize)
  }

  onResize() {
    console.log('"resize" event: %d x %d', screen.width, screen.height)
    this.forceUpdate()
  }

  render() {
    const logger = <Logger ref='logger' />
    //const logger = null
    let content = (
      <box
        width={55}
        left='center'
        top='center'
        shrink={true}
        border={{
          type: 'line'
        }}
        padding={{
          top: 0,
          left: 1,
          bottom: 1,
          right: 1,
        }}
        style={{
          border: {
            fg: 'red'
          }
        }}
      >
        <text top={1} left='center' style={{ bold: true, fg: 'blue' }}>Please select an action:</text>
        <list ref='actions' top={3} items={['Login', 'Configure Login Server URL', 'foo', 'bar','baz']} align='center' style={{ selected: { bg: 'blue', bold: true } }} keys={true} vi={true} mouse={true} />
      </box>
    )
    //content = <image file='/Users/nrajlich/Desktop/daftpunktocat-guy.gif' height={40} ascii={false} top={3} left={3} />
    //content = <box top={3} left={3}>{ inspect({ foo: 'bar'}, { colors: true }) }</box>
    content = <WritableBox top={3} left={3} width={20} ref='writable' style={{ bg: 'red' }} />
    //content = <Image top={3} left={3} width={80} height={40} draggable={true} border={{ type: 'line' }} style={{ border: { } }} src={process.argv[2] || '/Users/nrajlich/Desktop/stormtroopocat.png'} />
    return (
      <element>
        <Header>{pkg.displayName} v{pkg.version}</Header>
        { content }
        <Footer>Not currently logged in…</Footer>
        { logger }
      </element>
    )
  }
}

class Header extends Component {
  render() {
    /*
    const children = Children.toArray(this.props.children)
    if (children.length > 1) {
      console.warn('only 1 child inside is currently supported! Discarding: %j', children.slice(1))
    }
    */
    return (
      <box
        width='100%'
        top={0}
        left={0}
        { ...this.props }
      >
        <text
          left='center'
          style={{
            bold: true
          }}
        >{ this.props.children }</text>
        <line
          width='100%'
          top={1}
          left={0}
          orientation='horizontal'
          style={{
            fg: 'red'
          }}
        />
      </box>
    )
  }
}

class Footer extends Component {
  render() {
    return (
      <box
        width='100%'
        height={2}
        bottom={0}
        left={0}
        { ...this.props }
      >
        <line
          width='100%'
          bottom={1}
          left={0}
          orientation='horizontal'
          style={{
            fg: 'red'
          }}
        />
        <text
          left={2}
          bottom={0}
        >{ this.props.children }</text>
      </box>
    )
  }
}

const screen = blessed.screen({
  autoPadding: true,
  smartCSR: true,
  title: pkg.name
})

screen.key(['escape', 'q', 'C-c'], function(ch, key) {
  process.exit(0)
})

render(<App />, screen)
