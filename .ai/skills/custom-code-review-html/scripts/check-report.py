#!/usr/bin/env python3
"""Structural check for a code-review HTML report before publishing.

Usage: check-report.py <report.html>

Catches the failures that survive a visual skim: unbalanced tags, a language
block with no counterpart, font-relative widths that make the column resize on
language switch, and inline JS that does not parse. Exits non-zero on failure.
"""

import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path

VOID = {"br", "hr", "img", "input", "meta", "link", "source", "area", "col"}
# Boundary-matched so <header> does not read as <head>.
FORBIDDEN_TAGS = ("!doctype", "html", "head", "body")


def split(src):
    style = "\n".join(re.findall(r"<style>(.*?)</style>", src, re.S))
    script = "\n".join(re.findall(r"<script>(.*?)</script>", src, re.S))
    body = re.sub(r"<style>.*?</style>", "", src, flags=re.S)
    body = re.sub(r"<script>.*?</script>", "", body, flags=re.S)
    return style, script, body


def check_tags(body):
    stack, errors = [], []
    for m in re.finditer(r"<(/?)([a-zA-Z][\w-]*)([^>]*?)(/?)>", body):
        closing, name, selfclose = m.group(1), m.group(2).lower(), m.group(4)
        if name in VOID or selfclose:
            continue
        if closing:
            if not stack:
                errors.append(f"stray </{name}>")
            elif stack[-1] != name:
                errors.append(f"</{name}> closes <{stack[-1]}>")
                stack.pop()
            else:
                stack.pop()
        else:
            stack.append(name)
    if stack:
        errors.append("unclosed: " + ", ".join(stack))
    return errors


def check_lang(body):
    """Every lang="en" element needs a lang="ja" counterpart of the same tag.

    The negative lookbehind keeps data-lang="ja" from counting as a lang attr.
    """
    errors = []
    pat = lambda v: re.findall(r'<(\w+)[^>]*?(?<![-\w])lang="%s"' % v, body)
    en, ja = Counter(pat("en")), Counter(pat("ja"))
    if not en and not ja:
        return []
    for tag in set(en) | set(ja):
        if en.get(tag, 0) != ja.get(tag, 0):
            errors.append(f"<{tag}>: {en.get(tag, 0)} en vs {ja.get(tag, 0)} ja")
    return errors


def check_widths(style):
    """ch/em widths resize the column when the font changes on language switch."""
    hits = re.findall(r"(?:max-width|--measure|width):\s*[^;]*\d+(?:ch|em)\b", style)
    return [h.strip() for h in hits]


def check_js(script):
    if not script.strip():
        return []
    node = shutil.which("node")
    if not node:
        return ["node not on PATH — inline JS left unchecked"]
    with tempfile.NamedTemporaryFile("w", suffix=".js", delete=False, encoding="utf-8") as fh:
        fh.write(script)
        path = fh.name
    try:
        proc = subprocess.run([node, "--check", path], capture_output=True, text=True)
        return [] if proc.returncode == 0 else [proc.stderr.strip().splitlines()[0]]
    finally:
        Path(path).unlink(missing_ok=True)


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: check-report.py <report.html>")

    src = Path(sys.argv[1]).read_text(encoding="utf-8")
    style, script, body = split(src)

    checks = [
        ("document skeleton", [
            f"remove <{tag}> — the artifact host wraps the file"
            for tag in FORBIDDEN_TAGS
            if re.search(r"</?%s[\s>]" % re.escape(tag), src, re.I)
        ]),
        ("tag balance", check_tags(body)),
        ("css braces", [] if style.count("{") == style.count("}")
                       else [f'{style.count("{")} open vs {style.count("}")} close']),
        ("language pairing", check_lang(body)),
        ("font-relative widths", check_widths(style)),
        ("inline js parses", check_js(script)),
        ("title present", [] if re.search(r"<title>\s*\S", src) else ["no <title>"]),
    ]

    failed = False
    for label, errors in checks:
        if errors:
            failed = True
            print(f"FAIL  {label}")
            for e in errors:
                print(f"        {e}")
        else:
            print(f"ok    {label}")

    if failed:
        print("\nreport not ready to publish")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
