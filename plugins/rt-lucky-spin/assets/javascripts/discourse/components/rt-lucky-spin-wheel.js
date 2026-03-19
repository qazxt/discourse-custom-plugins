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
  @tracked lastResultKey = null;

  get segments() {
    return SEGMENTS;
  }

  get segmentAngle() {
    return 360 / SEGMENTS.length;
  }

  get wheelStyle() {
    return htmlSafe(`transform: rotate(${this.rotationDeg}deg);`);
  }

  segmentStyle(i) {
    return htmlSafe(`transform: rotate(${i * this.segmentAngle}deg);`);
  }

  segmentKeyForResult(result) {
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
    const key = this.segmentKeyForResult(result);
    if (!key) {
      return;
    }

    const idx = SEGMENTS.findIndex((s) => s.key === key);
    if (idx < 0) {
      return;
    }

    const center = idx * this.segmentAngle + this.segmentAngle / 2;
    const target = 360 - center;
    const extra = 360 * 5;
    const next = (this.rotationDeg % 360) + extra + target;

    this.animating = true;
    this.rotationDeg = next;
    await new Promise((resolve) => setTimeout(resolve, 3200));
    this.animating = false;
  }

  @action
  onResultChanged() {
    const key = this.segmentKeyForResult(this.args.result);
    if (!key || key === this.lastResultKey) {
      return;
    }
    this.lastResultKey = key;
    this.spinToResult(this.args.result);
  }
}

