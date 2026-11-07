export type PadSample = { buttons: readonly {pressed:boolean}[]; axes: readonly number[] };
export class PadInput {
  private held = new Set<number>();
  connected = false;
  sample(pad: PadSample | null) {
    const previous = this.held;
    this.held = new Set(pad?.buttons.flatMap((button,index)=>button.pressed?[index]:[])??[]);
    const disconnected = this.connected && !pad;
    this.connected = !!pad;
    const axis = (index:number) => Math.abs(pad?.axes[index]??0)>.25 ? Math.max(-1,Math.min(1,pad!.axes[index])) : 0;
    return {
      pressed:[...this.held].filter(button=>!previous.has(button)),
      released:[...previous].filter(button=>!this.held.has(button)),
      direction: this.held.has(15)?1:this.held.has(14)?-1:Math.sign(axis(0)),
      aimX: axis(2)||axis(0)||(this.held.has(15)?1:this.held.has(14)?-1:0),
      aimY: axis(3)||axis(1)||(this.held.has(13)?1:this.held.has(12)?-1:0),
      disconnected,
    };
  }
}
