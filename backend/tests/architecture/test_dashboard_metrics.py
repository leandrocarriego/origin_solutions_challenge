"""The Grafana dashboard may only chart metrics that the code actually exposes.

A renamed counter breaks nothing loudly: every panel that used it goes quietly empty, which
reads as "no traffic" instead of "the dashboard is lying". This test turns that silent failure
into a red build, and it is the only thing standing between the quota's evidence and a chart
nobody can trust.

It reads the dashboard the way Grafana does --from the JSON on disk-- so it also covers the
copy that gets provisioned, not a fixture that resembles it.
"""

import json
import re
from pathlib import Path
from typing import Any

import pytest
from prometheus_client import REGISTRY

# Importing the module is what registers the metrics; nothing else here uses the name.
from app import observability  # noqa: F401

REPO_ROOT = Path(__file__).resolve().parents[3]
DASHBOARD_DIR = REPO_ROOT / "infra" / "grafana" / "dashboards"

# The four counters the quota rests on. They exist to be looked at, so a dashboard that does
# not chart one of them is a dashboard that cannot answer the question they were added for.
ARTICLE_II_METRICS = (
    "provider_requests_total",
    "quote_cache_hits_total",
    "quote_cache_misses_total",
    "provider_quota_remaining",
)

# PromQL functions, aggregation operators and keywords. Whatever survives their removal is a
# metric name, because label names are stripped earlier along with the syntax that carries them.
PROMQL_VOCABULARY = frozenset(
    {
        "abs",
        "absent",
        "avg",
        "avg_over_time",
        "bottomk",
        "by",
        "ceil",
        "changes",
        "clamp",
        "clamp_max",
        "clamp_min",
        "count",
        "count_over_time",
        "count_values",
        "day_of_month",
        "day_of_week",
        "delta",
        "deriv",
        "exp",
        "floor",
        "group",
        "group_left",
        "group_right",
        "histogram_quantile",
        "hour",
        "idelta",
        "ignoring",
        "increase",
        "irate",
        "label_join",
        "label_replace",
        "last_over_time",
        "ln",
        "log2",
        "log10",
        "max",
        "max_over_time",
        "min",
        "min_over_time",
        "minute",
        "month",
        "offset",
        "on",
        "or",
        "and",
        "unless",
        "predict_linear",
        "present_over_time",
        "quantile",
        "quantile_over_time",
        "rate",
        "resets",
        "round",
        "scalar",
        "sgn",
        "sort",
        "sort_desc",
        "sqrt",
        "stddev",
        "stdvar",
        "sum",
        "sum_over_time",
        "time",
        "timestamp",
        "topk",
        "vector",
        "without",
        "year",
        "bool",
        "inf",
        "nan",
    }
)

_LABEL_SELECTOR = re.compile(r"\{[^}]*\}")
_RANGE_SELECTOR = re.compile(r"\[[^\]]*\]")
_GROUPING_CLAUSE = re.compile(r"\b(?:by|without|on|ignoring|group_left|group_right)\s*\([^)]*\)")
_STRING_LITERAL = re.compile(r"\"[^\"]*\"|'[^']*'")
_IDENTIFIER = re.compile(r"[a-zA-Z_][a-zA-Z0-9_]*")

# What a metric of each type is actually called on the wire. Derived from the type instead of
# from the samples, because a labelled metric publishes no samples until it is first used, and
# the suite runs against a process that never served a request.
_SUFFIXES_BY_TYPE = {
    "counter": ("_total", "_created"),
    "histogram": ("_bucket", "_sum", "_count", "_created"),
    "summary": ("_sum", "_count", "_created"),
    "gauge": (),
    "info": ("_info",),
    "unknown": (),
}


def exposed_metric_names() -> frozenset[str]:
    """Every name the backend can publish, including the suffixed forms."""
    names: set[str] = set()
    for metric in REGISTRY.collect():
        names.add(metric.name)
        for suffix in _SUFFIXES_BY_TYPE.get(metric.type, ()):
            names.add(f"{metric.name}{suffix}")
    return frozenset(names)


def dashboard_files() -> list[Path]:
    """Every dashboard that gets provisioned into Grafana."""
    return sorted(DASHBOARD_DIR.glob("*.json"))


def _expressions(node: Any) -> list[str]:
    """Pull every PromQL expression out of a dashboard, at any depth."""
    found: list[str] = []
    if isinstance(node, dict):
        expr = node.get("expr")
        if isinstance(expr, str) and expr.strip():
            found.append(expr)
        for value in node.values():
            found.extend(_expressions(value))
    elif isinstance(node, list):
        for item in node:
            found.extend(_expressions(item))
    return found


def referenced_metrics(expression: str) -> set[str]:
    """Reduce a PromQL expression to the metric names it reads."""
    stripped = _STRING_LITERAL.sub(" ", expression)
    stripped = _GROUPING_CLAUSE.sub(" ", stripped)
    stripped = _LABEL_SELECTOR.sub(" ", stripped)
    stripped = _RANGE_SELECTOR.sub(" ", stripped)
    # Grafana's own template variables ($job, [[job]]) are not metrics.
    stripped = re.sub(r"\$\w+|\$\{[^}]*\}", " ", stripped)
    return {
        token
        for token in _IDENTIFIER.findall(stripped)
        if token not in PROMQL_VOCABULARY and not token.isdigit()
    }


def test_there_is_at_least_one_dashboard() -> None:
    """A provisioning directory with no dashboard means the other tests pass vacuously."""
    assert dashboard_files(), f"no dashboards found in {DASHBOARD_DIR}"


@pytest.mark.parametrize("path", dashboard_files(), ids=lambda p: p.name)
def test_dashboard_is_valid_json_with_a_stable_uid(path: Path) -> None:
    """Provisioning matches on uid: without one, every restart creates a duplicate."""
    dashboard = json.loads(path.read_text(encoding="utf-8"))

    assert dashboard.get("uid"), f"{path.name} has no uid"
    assert dashboard.get("title"), f"{path.name} has no title"


@pytest.mark.parametrize("path", dashboard_files(), ids=lambda p: p.name)
def test_every_charted_metric_exists_in_the_code(path: Path) -> None:
    """The panels read metrics the backend really publishes, suffix included."""
    dashboard = json.loads(path.read_text(encoding="utf-8"))
    available = exposed_metric_names()

    unknown: dict[str, str] = {}
    for expression in _expressions(dashboard):
        for metric in referenced_metrics(expression):
            if metric not in available:
                unknown[metric] = expression

    assert not unknown, f"{path.name} charts metrics the backend does not expose: " + "; ".join(
        f"{name!r} in {expr!r}" for name, expr in sorted(unknown.items())
    )


@pytest.mark.parametrize("metric", ARTICLE_II_METRICS)
def test_every_article_ii_metric_is_charted_somewhere(metric: str) -> None:
    """The counters that make the quota checkable are on a panel, not just in the registry."""
    charted: set[str] = set()
    for path in dashboard_files():
        dashboard = json.loads(path.read_text(encoding="utf-8"))
        for expression in _expressions(dashboard):
            charted |= referenced_metrics(expression)

    assert metric in charted, f"{metric} is exposed but no panel charts it"
