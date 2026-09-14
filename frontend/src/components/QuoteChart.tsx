/**
 * The chart of wireframe 03, drawn with Highcharts (RF-14, RF-15, RF-36, RF-38).
 *
 * Highcharts and not a React wrapper: what this screen needs is a `useRef` and two effects, and a
 * wrapper would be a dependency to keep for twenty lines (`plan.md` → *Alternativas descartadas*).
 *
 * **The chart is created once and updated in place.** The effect that builds it depends on
 * nothing that a refresh changes, and the one that carries new points calls `setData` on the chart
 * that already exists: that is RF-19 -- the node stays the same, so the chart does not blink and
 * the points that were already drawn stay drawn (RF-20). Remounting is the screen's decision and
 * it has one trigger, the `key` it gives this component when somebody presses `Graficar` (RF-17).
 *
 * **The hours are not computed here.** They come from `quotes/market.ts`, which is pure and
 * therefore testable: Highcharts draws inside an SVG, jsdom computes no layout and a `formatter`
 * never runs there, so arithmetic written in this file would be arithmetic no test can read.
 *
 * **Zoom, range selection, the export menu and the credit are turned off explicitly.** Highcharts
 * ships them switched on and the spec leaves them out: a screen that offers them does something
 * nobody asked for (UI-01).
 */

import Highcharts from 'highcharts';
import { useEffect, useRef, type JSX } from 'react';

import type { QuotePoint } from '../api/quotes';
import { marketClockValue, tooltipTimeLines } from '../quotes/market';

/** Verbatim from the `Detalle de Acción` table of docs/design/COPY.md (UI-02). */
const EJE_Y = 'Cotización';
const EJE_X = 'Intervalo';

/**
 * One value of the `@theme` block of `tokens.css`, or nothing when it is not there (UI-03).
 *
 * Highcharts is configured in JavaScript and takes colours as values, so the palette is read from
 * where it is declared instead of being written a second time here. When the stylesheet is not
 * loaded -- which is every test -- the answer is empty and Highcharts falls back to its own.
 */
function token(name: string): string | undefined {
  const value = getComputedStyle(document.documentElement).getPropertyValue(name).trim();

  return value === '' ? undefined : value;
}

/** The tooltip's font, or nothing to say about it when the stylesheet is not there (UI-04). */
function mono(): Highcharts.CSSObject {
  const family = token('--font-mono');

  return family === undefined ? {} : { fontFamily: family };
}

/**
 * One label of the horizontal axis: the market hour, on its own (RF-36).
 *
 * The hour and not the whole reading, because that is what the wireframe writes -- `13:10`,
 * `13:11` -- and a date repeated on every tick covers the axis it is labelling.
 *
 * A tick that is not a finite instant gets no label rather than an error: an axis is laid out
 * before it has anything to lay out -- and in a runner with no layout it can stay that way -- and
 * a chart that throws while measuring itself draws nothing at all.
 */
function marketLabel(value: number | string): string {
  const instant = typeof value === 'number' ? value : Number(value);

  return Number.isFinite(instant) ? marketClockValue(new Date(instant)) : '';
}

/** The series, as Highcharts takes it: the instant as a number, the price as one (RF-15). */
function pointsFor(points: QuotePoint[]): [number, number][] {
  return points.map((point) => [Date.parse(point.ts), Number(point.price)]);
}

/** The colour of the line, from the palette, or nothing when the stylesheet is not there. */
function colour(): { color?: string } {
  const value = token('--color-link');

  return value === undefined ? {} : { color: value };
}

export function QuoteChart({
  symbol,
  points,
}: {
  symbol: string;
  points: QuotePoint[];
}): JSX.Element {
  const container = useRef<HTMLDivElement | null>(null);
  const chart = useRef<Highcharts.Chart | null>(null);
  // The points of the refresh, kept where the effect that builds the chart can read them without
  // depending on them: depending on them would rebuild the chart on every refresh, which is the
  // remount RF-19 forbids. It is written from an effect, because a ref written while rendering is
  // a value React is allowed to throw away.
  const latest = useRef(points);

  useEffect(() => {
    latest.current = points;
  }, [points]);

  useEffect(() => {
    if (container.current === null) return undefined;

    chart.current = Highcharts.chart(container.current, {
      // UI-01: what Highcharts brings switched on and the spec leaves out. No zoom of any kind
      // -- neither dragged nor with the wheel -- and no panning: this chart is read, not explored.
      chart: { zooming: { mouseWheel: { enabled: false } }, panning: { enabled: false } },
      title: { text: symbol },
      credits: { enabled: false },
      exporting: { enabled: false },
      legend: { enabled: false },
      xAxis: {
        type: 'datetime',
        title: { text: EJE_X },
        labels: {
          formatter(): string {
            return marketLabel(this.value);
          },
        },
      },
      yAxis: { title: { text: EJE_Y } },
      tooltip: {
        // UI-04: numbers, dates and symbols line up only in tabular mono. The family is read from
        // the `@theme` block, so the tooltip and the rest of the screen cannot drift apart.
        style: mono(),
        formatter(): string {
          const [market, local] = tooltipTimeLines(new Date(this.x));

          return `${market}<br/>${local}<br/>${EJE_Y}: ${this.y ?? ''}`;
        },
      },
      // Instants are absolute and the axis works in UTC; what a person reads is written by
      // `quotes/market.ts`, in the market's hour (RF-36). Handing Highcharts the zone instead --
      // `time.timezone` -- would put the same reading on the labels *and* would make every
      // redraw throw under jsdom, where its timezone arithmetic does not survive: the refresh of
      // RF-19 is a redraw, so that option cannot be tested at all. Doing the conversion in the
      // pure module keeps the hours where a test can read them and the chart where it can run.
      series: [
        {
          type: 'line',
          name: symbol,
          ...colour(),
          data: pointsFor(latest.current),
        },
      ],
    });

    return () => {
      chart.current?.destroy();
      chart.current = null;
    };
  }, [symbol]);

  useEffect(() => {
    // `setData` and not a new chart: the same node, redrawn (RF-19), keeping what was already on
    // it (RF-20). `false` for the animation, because a line that slides on every refresh is a
    // chart that is hard to read while it moves.
    chart.current?.series[0]?.setData(pointsFor(points), true, false);
  }, [points]);

  return <div ref={container} />;
}
