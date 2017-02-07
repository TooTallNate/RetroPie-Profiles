#!/usr/bin/env node
import {format} from 'util'
import pkg from '../package.json'

// XXX: this import order is important…
// DO NOT re-arrange or else react-blessed breaks :/
import React, {Component} from 'react'
import blessed from 'blessed'
import {render} from 'react-blessed'

class App extends Component {
  componentDidMount() {
    screen.on('resize', () => this.forceUpdate())
  }

  render() {
    return (
      <element>
        <box
          width='100%'
          top={0}
          left={0}
          style={{
            bold: true
          }}
          align='center'
        >
          {pkg.displayName} v{pkg.version}
        </box>
        <line
          width='100%'
          top={1}
          left={0}
          orientation='horizontal'
          style={{
            fg: 'red'
          }}
        />
        <box
          width='50%'
          height='50%'
          left="center"
          top="center"
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
            //fg: 'blue',
            border: {
              //fg: 'red'
            }
          }}
          align='center'
          label='RetroPie Profiles'
        >
          {screen.width} x {screen.height}
        </box>
      </element>
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
