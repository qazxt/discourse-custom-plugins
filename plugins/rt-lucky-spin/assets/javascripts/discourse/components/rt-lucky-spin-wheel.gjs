import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";

const SEGMENTS = [
  { key: "points_100", label: "100" },
  { key: "points_25", label: "25" },
  { key: "points_5", label: "5" },
  { key: "product", label: "🎁" },
  { key: "no_prize", label: "😅" },
];

export default class RtLuckySpinWheel extends Component {
  @tracked rotationDeg = 0;
  @tracked animating = false;
  @tracked _lastResultKey = null;

  get segments() {
    return SEGMENTS;
  }

  get segmentAngle() {
    return 360 / SEGMENTS.length;
  }

  get wheelStyle() {
    return `transform: rotate(${this.rotationDeg}deg);`;
  }

  segmentStyle(i) {
    return htmlSafe(`transform: rotate(${i * this.segmentAngle}deg);`);
  }

  #segmentKeyForResult(result) {
    if (!result) {
      return null;
    }
    if (result.type === "points") {
      if (result.points === 100) return "points_100";
      if (result.points === 25) return "points_25";
      return "points_5";
    }
    if (result.type === "product") return "product";
    return "no_prize";
  }

  @action
  async spinToResult(result) {
    const key = this.#segmentKeyForResult(result);
    if (!key) {
      return;
    }

    const idx = SEGMENTS.findIndex((s) => s.key === key);
    if (idx < 0) {
      return;
    }

    // 指针固定在顶部（0deg），让目标扇区中心对齐顶部：
    // 扇区中心角度 = idx*seg + seg/2；需要转到 360 - center
    const center = idx * this.segmentAngle + this.segmentAngle / 2;
    const target = 360 - center;

    // 增加多圈旋转，保证有“转盘”手感
    const extra = 360 * 5;
    const next = (this.rotationDeg % 360) + extra + target;

    this.animating = true;
    this.rotationDeg = next;

    // 等动画结束后解除 animating
    await new Promise((resolve) => setTimeout(resolve, 3200));
    this.animating = false;
  }

  @action
  onResultChanged() {
    const key = this.#segmentKeyForResult(this.args.result);
    if (!key || key === this._lastResultKey) {
      return;
    }
    this._lastResultKey = key;
    this.spinToResult(this.args.result);
  }
}

<template>
  <div class="rt-lucky-spin-wheel" {{did-update this.onResultChanged @result}}>
    <div class="rt-lucky-spin-wheel__pointer" aria-hidden="true"></div>

    <div
      class="rt-lucky-spin-wheel__wheel {{if this.animating 'is-animating'}}"
      style={{this.wheelStyle}}
      aria-label="Lucky Spin Wheel"
    >
      {{#each this.segments as |seg i|}}
        <div
          class="rt-lucky-spin-wheel__segment"
          style={{this.segmentStyle i}}
        >
          <div class="rt-lucky-spin-wheel__segment-inner">
            <span class="rt-lucky-spin-wheel__segment-label">{{seg.label}}</span>
          </div>
        </div>
      {{/each}}
    </div>
  </div>
</template>

