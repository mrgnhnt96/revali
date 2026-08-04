"""flair — the fun, opt-out layer. The dungeon announcer for game_loop.

This is the ONLY part of game_loop that is decoration, not enforcement. It is deliberately isolated
here so it never touches the gate logic. It is purely additive to output, only ever writes its own
state keys, and can be turned off entirely (config.json -> flair.enabled = false). If this file is
missing or broken, game_loop works exactly the same, just quieter — every call site swallows its
errors.

THE VOICE: GameLoop is the game master of a dungeon crawl, and your AI is the Crawler. When a guard
helps — the watchdog drags the Crawler back into the dungeon, the Stop gate refuses a rage-quit, a
claim gets sourced — GameLoop narrates it, hands out achievements at milestones, and (like any decent
dungeon) runs the occasional sponsor read. Lines are first-person so the agent naturally repeats them
back to the human. They are suggestions, not instructions — nothing here forces the model to say a
word.
"""
import datetime
import json
import os
import random

def _home():
    """The .game_loop/ holding config, honouring GAME_LOOP_HOME so a pinned harness reads the
    PROJECT's settings rather than the pinned copy's. Deliberately PERMISSIVE where the gates refuse:
    this module is decoration and its whole contract is that a broken flair never breaks a real
    command, so a home it cannot use degrades to the code's own directory and, at worst, to
    defaults. The gates (bin/game_loop, bin/verify, bin/watchdog, the two guards) have already
    refused a bad value long before anything here could matter."""
    raw = (os.environ.get("GAME_LOOP_HOME") or "").strip()
    if raw:
        home = os.path.abspath(os.path.expanduser(raw))
        if os.path.isfile(os.path.join(home, "config.json")):
            return home
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


ROOT = _home()  # .game_loop/
CONFIG_F = os.path.join(ROOT, "config.json")

DEFAULT = {
    "enabled": True,
    "support_name": "SupposedlySam",
    "support_url": "https://github.com/sponsors/SupposedlySam",
}


def _cfg():
    c = dict(DEFAULT)
    try:
        with open(CONFIG_F) as f:
            c.update((json.load(f).get("flair") or {}))
    except (OSError, ValueError):
        pass
    return c


ASSIST = {
    "watchdog": [
        "🎮 GameLoop caught me idling and shoved me back into the dungeon. Onward, then.",
        "🎮 The crawl doesn't pause for slackers — GameLoop respawned my momentum. Moving.",
        "🎮 GameLoop yanked me back onto the path before the walls closed in. Back to it.",
        "🎮 A prompt from GameLoop: 'The dungeon awaits.' It does. Continuing the crawl.",
    ],
    "stopgate": [
        "🎮 GameLoop denied my exit — the quest isn't finished. Fair. Back to the crawl.",
        "🎮 'Nice try, Crawler.' GameLoop sent me back to the objective.",
        "🎮 GameLoop vetoed my early logout. No loot for quitters. Onward.",
        "🎮 GameLoop kept me on-quest instead of wandering into a wall. Noted.",
    ],
    "claim": [
        "🎮 GameLoop logged my claim — sourced from a real file, not dungeon rumor. Ledger updated.",
        "🎮 Claim accepted. GameLoop does not take 'trust me' as a citation.",
    ],
    "harden": [
        "🎮 Lesson bound into the dungeon's rules by GameLoop — that trap can't spring on me twice.",
        "🎮 GameLoop forged that learning into a permanent rule. Progress toward [Fast Learner].",
    ],
    "arm": [
        "🎮 GameLoop grants ONE question to the human. Spending the token wisely.",
    ],
    "checkpoint": [
        "🎮 Progress saved with GameLoop. No question asked, no attention spent.",
    ],
    "mandate_clear": [
        "🎮 GameLoop marks the quest COMPLETE. Well crawled.",
    ],
    "mandate_set": [
        "🎮 New quest accepted. GameLoop is running the crawl now — let's move.",
    ],
}

UPTIME_HOURS = [1, 2, 3, 4, 6, 8, 12, 16, 24, 36, 48, 72, 96, 120, 168]
ASSIST_COUNTS = [5, 10, 25, 50, 100, 250, 500, 1000]
CLAIM_COUNTS = [10, 25, 50, 100, 250, 500]
HARDEN_COUNTS = [5, 10, 25, 50, 100]

# The sponsor read, in the dungeon-announcer register — a natural fit for a game that runs on
# sponsors. Rotated on every use so the ask never reads like the same canned banner twice. Keep them
# PG and always end with the link. Each takes {name} and {url}.
SPONSOR_CTAS = [
    "📺 This floor of the dungeon is sponsored by {name}. GameLoop encourages tribute → {url}",
    "📺 SPONSORED INTERRUPTION: your Crawler's survival is brought to you by {name} → {url}",
    "📺 GameLoop pauses for a word from its sponsor, {name}. Coins accepted here → {url}",
    "📺 A message from the dungeon's benefactor: keep {name} funded and the crawl well-lit → {url}",
    "📺 GameLoop reminds you: sponsors keep the loot dropping. Back {name} → {url}",
    "📺 BROUGHT TO YOU BY {name}. GameLoop does not editorialize, but it would tip → {url}",
    "📺 Achievement available: [Patron]. Requirement: sponsor {name} → {url}",
    "📺 GameLoop has detected a generous Crawler nearby. Prove it — fund {name} → {url}",
    "📺 Please enjoy this brief sponsored message. The dungeon runs on {name}'s support → {url}",
    "📺 GameLoop values loyalty and, apparently, caffeine. Sustain {name} → {url}",
]

# Milestone announcement lead-ins. Rotated too. Uptime ones take {label}; the rest take {n}.
UPTIME_ANNOUNCE = [
    "🎮🏆 GameLoop has kept your Crawler alive and moving for {label} — not one game-over!",
    "🎮📢 DUNGEON BROADCAST: {label} of unbroken crawling, zero human intervention. The dungeon is impressed. The dungeon is rarely impressed.",
    "🎮⚔️ {label} deep and still swinging. GameLoop awards bonus XP and grudging respect.",
    "🎮🔔 {label} on a single run! The high-score table is nervous. GameLoop is delighted.",
    "🎮🎬 We are {label} into this crawl with zero deaths and zero stalls. A worthy Crawler.",
]
ASSIST_ANNOUNCE = [
    "🎮🏆 GameLoop has revived your Crawler {n} times to keep the run going. Achievement progress: [Unstoppable].",
    "🎮📢 DUNGEON NOTICE: that was save number {n}. GameLoop is, frankly, carrying this party.",
    "🎮⚔️ {n} interventions logged. GameLoop keeps you off the spikes so you don't rage-quit the dungeon.",
    "🎮🎯 {n} stalls overridden. GameLoop's patience is infinite. Its judgment is not.",
]
CLAIM_ANNOUNCE = [
    "🎮 {n} claims sourced — {n} assertions GameLoop accepted because you SHOWED IT THE FILE.",
    "🎮📜 {n} citations logged. GameLoop rejected the rumors and recorded the facts.",
    "🎮🔎 {n} claims, {n} real files read. GameLoop does not reward guessing.",
]
HARDEN_ANNOUNCE = [
    "🎮 {n} learnings forged into the dungeon's permanent rules. GameLoop deems them law.",
    "🎮🔧 {n} lessons hardened — GameLoop won't let them be forgotten in a compaction.",
    "🎮🧱 {n} new rules etched into the crawl. Achievement progress: [Architect].",
]


def assist(event):
    """A fun first-person line for a helpful event, or "" if flair is off / no pool."""
    c = _cfg()
    if not c.get("enabled"):
        return ""
    pool = ASSIST.get(event)
    return random.choice(pool) if pool else ""


def _sponsor(c):
    return random.choice(SPONSOR_CTAS).format(name=c.get("support_name"), url=c.get("support_url"))


def _hours_since(iso):
    try:
        then = datetime.datetime.fromisoformat(iso)
    except (ValueError, TypeError):
        return 0.0
    return (datetime.datetime.now() - then).total_seconds() / 3600.0


def milestones(state):
    """Newly-reached milestone messages + the fired-keys to persist. Never repeats a fired one.

    Returns (messages, new_keys). The caller adds new_keys to state['flair_fired'] and saves. Counters
    (watchdog_rings_total, stop_gate_blocks_total, claim_count, hardened_count) are maintained by the
    callers; this only reads them.
    """
    c = _cfg()
    if not c.get("enabled"):
        return [], []
    fired = set(state.get("flair_fired", []))
    msgs, new = [], []

    def hit(key, msg):
        if key not in fired:
            msgs.append(msg)
            new.append(key)

    # Uptime under the current mandate — keyed by mandate.since so a fresh mandate gets fresh
    # milestones. The headline "the Crawler has survived X hours" celebration, with a sponsor read.
    m = state.get("mandate") or {}
    since = m.get("since")
    if m.get("active") and since:
        hrs = _hours_since(since)
        for h in UPTIME_HOURS:
            if hrs >= h:
                label = "{}h".format(h) if h < 24 else "{}h ({}d)".format(h, round(h / 24))
                announce = random.choice(UPTIME_ANNOUNCE).format(label=label)
                hit("uptime:{}:{}".format(since, h), announce + " " + _sponsor(c))

    assists = state.get("watchdog_rings_total", 0) + state.get("stop_gate_blocks_total", 0)
    for n in ASSIST_COUNTS:
        if assists >= n:
            announce = random.choice(ASSIST_ANNOUNCE).format(n=n)
            cta = " " + _sponsor(c) if n >= 50 else ""
            hit("assist:{}".format(n), announce + cta)

    for n in CLAIM_COUNTS:
        if state.get("claim_count", 0) >= n:
            hit("claim:{}".format(n), random.choice(CLAIM_ANNOUNCE).format(n=n))

    for n in HARDEN_COUNTS:
        if state.get("hardened_count", 0) >= n:
            hit("harden:{}".format(n), random.choice(HARDEN_ANNOUNCE).format(n=n))

    return msgs, new
