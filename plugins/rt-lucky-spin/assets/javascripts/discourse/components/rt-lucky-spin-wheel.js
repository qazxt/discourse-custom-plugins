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

/** 与 conic-gradient（0°=12 点顺时针）一致：每扇等角，与中奖概率无关；马卡龙系柔和色 */
const CONIC_COLORS = [
  "#ffeaa7",
  "#fab1a0",
  "#74b9ff",
  "#a29bfe",
  "#55efc4",
];

function nextFrame() {
  return new Promise((resolve) => requestAnimationFrame(resolve));
}

export default class RtLuckySpinWheel extends Component {
  @tracked rotationDeg = 0;
  @tracked animating = false;

  get segments() {
    return SEGMENTS;
  }

  get segmentAngle() {
    return 360 / SEGMENTS.length;
  }

  get wheelStyle() {
    return htmlSafe(`transform: rotate(${this.rotationDeg}deg);`);
  }

  /** 五等分 conic：0° 在 12 点、顺时针（与 转盘参考.html 一致） */
  get faceStyle() {
    const n = SEGMENTS.length;
    const a = this.segmentAngle;
    const parts = [];
    for (let i = 0; i < n; i++) {
      const c = CONIC_COLORS[i % CONIC_COLORS.length];
      parts.push(`${c} ${i * a}deg ${(i + 1) * a}deg`);
    }
    return htmlSafe(`background: conic-gradient(${parts.join(", ")});`);
  }

  /**
   * 参考转盘：圆心为 (0,0)，极坐标放到扇区角平分线上，再 rotate + translateX(-50%) 对齐中线。
   * centerAngle：从 12 点顺时针，单位度。
   */
  @action
  labelStyle(i) {
    const centerAngle = (i + 0.5) * this.segmentAngle;
    const radius = 125;
    const radian = ((centerAngle - 90) * Math.PI) / 180;
    const x = Math.cos(radian) * radius;
    const y = Math.sin(radian) * radius;
    return htmlSafe(
      `transform: translate(${x}px, ${y}px) rotate(${centerAngle}deg) translateX(-50%);`
    );
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

    const sectorAngle = this.segmentAngle;
    const targetCenterAngle = idx * sectorAngle + sectorAngle / 2;
    const rotateToTarget = (360 - targetCenterAngle) % 360;
    const extraSpins = 360 * 6;
    const currentMod = ((this.rotationDeg % 360) + 360) % 360;
    const nextRotation =
      this.rotationDeg + (extraSpins + rotateToTarget - currentMod);

    this.animating = false;
    await nextFrame();
    this.animating = true;
    await nextFrame();
    this.rotationDeg = nextRotation;

    await new Promise((resolve) => setTimeout(resolve, 4100));
    this.animating = false;
  }

  @action
  onResultChanged() {
    const key = this.segmentKeyForResult(this.args.result);
    if (!key) {
      return;
    }
    this.spinToResult(this.args.result);
  }
}
