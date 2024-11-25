#!/bin/bash
git-cliff -o CHANGELOG.md
git add CHANGELOG.md
git commit -m "chore: update changelog"
