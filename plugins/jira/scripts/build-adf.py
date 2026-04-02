#!/usr/bin/env python3
"""Convert markdown-ish text to Jira ADF (Atlassian Document Format).

Usage: build-adf.py <wrap_key> [time_spent] < input.md
  wrap_key: "comment" for worklog endpoint, "body" for comment endpoint
  time_spent: optional, e.g. "2h 30m"

Reads content from stdin, outputs JSON to stdout.
"""

import json
import sys
import re


def build_adf(content, wrap_key, time_spent=""):
    lines = content.split('\n')
    adf_content = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Detect headings (markdown ##)
        heading_match = re.match(r'^(#{1,6})\s+(.*)', line)
        if heading_match:
            level = len(heading_match.group(1))
            text = heading_match.group(2)
            adf_content.append({
                'type': 'heading',
                'attrs': {'level': level},
                'content': [{'type': 'text', 'text': text}]
            })
            i += 1
            continue

        # Detect table/preformatted blocks (box-drawing chars or pipe-based tables)
        if re.search(r'[┌┐└┘├┤┬┴┼─│═║╔╗╚╝╠╣╦╩╬]', line):
            block_lines = []
            while i < len(lines):
                l = lines[i]
                is_table = re.search(r'[┌┐└┘├┤┬┴┼─│═║╔╗╚╝╠╣╦╩╬]', l)
                is_indented_pipe = l.startswith('  ') and re.search(r'[│|]', l)
                is_empty = l.strip() == ''

                if is_table or is_indented_pipe or (is_empty and block_lines):
                    block_lines.append(l)
                    i += 1
                    # Stop on empty line if next line isn't part of table
                    if is_empty and i < len(lines):
                        next_l = lines[i]
                        if not re.search(r'[┌┐└┘├┤┬┴┼─│═║╔╗╚╝╠╣╦╩╬│|]', next_l):
                            break
                else:
                    break

            # Remove trailing empty lines
            while block_lines and block_lines[-1].strip() == '':
                block_lines.pop()

            adf_content.append({
                'type': 'codeBlock',
                'attrs': {'language': 'text'},
                'content': [{'type': 'text', 'text': '\n'.join(block_lines)}]
            })
            continue

        # Bullet list items (- or *)
        if re.match(r'^[\s]*[-*]\s+', line):
            list_items = []
            while i < len(lines) and re.match(r'^[\s]*[-*]\s+', lines[i]):
                item_text = re.sub(r'^[\s]*[-*]\s+', '', lines[i])
                list_items.append({
                    'type': 'listItem',
                    'content': [{
                        'type': 'paragraph',
                        'content': [{'type': 'text', 'text': item_text}]
                    }]
                })
                i += 1
            adf_content.append({
                'type': 'bulletList',
                'content': list_items
            })
            continue

        # Numbered list items (1. 2. etc)
        if re.match(r'^[\s]*\d+\.\s+', line):
            list_items = []
            while i < len(lines) and re.match(r'^[\s]*\d+\.\s+', lines[i]):
                item_text = re.sub(r'^[\s]*\d+\.\s+', '', lines[i])
                list_items.append({
                    'type': 'listItem',
                    'content': [{
                        'type': 'paragraph',
                        'content': [{'type': 'text', 'text': item_text}]
                    }]
                })
                i += 1
            adf_content.append({
                'type': 'orderedList',
                'content': list_items
            })
            continue

        # Empty line — skip
        if line.strip() == '':
            i += 1
            continue

        # Regular paragraph with inline formatting (**bold**)
        inline_content = []
        parts = re.split(r'(\*\*[^*]+\*\*)', line)
        for part in parts:
            if part.startswith('**') and part.endswith('**'):
                inline_content.append({
                    'type': 'text',
                    'text': part[2:-2],
                    'marks': [{'type': 'strong'}]
                })
            elif part:
                inline_content.append({'type': 'text', 'text': part})

        if inline_content:
            adf_content.append({
                'type': 'paragraph',
                'content': inline_content
            })

        i += 1

    # Fallback if nothing was parsed
    if not adf_content:
        adf_content = [{
            'type': 'paragraph',
            'content': [{'type': 'text', 'text': content.strip()}]
        }]

    # Add attribution line for Claude-generated comments
    adf_content.append({
        'type': 'rule'
    })
    adf_content.append({
        'type': 'paragraph',
        'content': [{
            'type': 'text',
            'text': 'Posted via claude-code-jira',
            'marks': [{'type': 'em'}, {'type': 'textColor', 'attrs': {'color': '#97a0af'}}]
        }]
    })

    payload = {
        wrap_key: {
            'type': 'doc',
            'version': 1,
            'content': adf_content
        }
    }

    if wrap_key == 'comment' and time_spent:
        payload['timeSpent'] = time_spent

    return payload


if __name__ == '__main__':
    wrap_key = sys.argv[1] if len(sys.argv) > 1 else 'body'
    time_spent = sys.argv[2] if len(sys.argv) > 2 else ''
    content = sys.stdin.read()
    payload = build_adf(content, wrap_key, time_spent)
    print(json.dumps(payload))
