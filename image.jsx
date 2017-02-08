import Canvas from 'canvas'
import { readFile } from 'fs-promise'
import ansiRender from 'ansi-canvas-render'
import React, {Component} from 'react'

import WritableBox from './writable-box'

export default class Image extends WritableBox {
  constructor(...args) {
    super(...args)
  }

  async componentDidMount() {
    const { width, height } = this.refs.box
    this.canvas = new Canvas(width - 2, (height * 2) - 2)
    this.context = this.canvas.getContext('2d')

    this.img = new Canvas.Image()
    this.img.src = await readFile(this.props.src)

    const scaleW = this.img.width > width ? width / this.img.width : 1;
    const w = Math.floor(this.img.width * scaleW);
    const h = Math.floor(this.img.height * scaleW);
    console.log({ scaleW, w, h })

    const ctx = this.context
    ctx.fillStyle = 'white'
    ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)

    ctx.drawImage(this.img, 0, 0, w, h)

    ansiRender(this.canvas, { stream: this.writable, small: true })
  }
}
